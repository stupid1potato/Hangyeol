//! Thin Hangyeol FFI over `rhwp::document_core::DocumentCore`.
//!
//! No OLE/HWP binary parser of our own, no ZIP/XML product writer, no
//! renderer / layout / WASM UI exports. Save always clears `line_segs`
//! (verified Hangyeol recipe) before `export_hwpx_native`.

mod error;

pub use error::{HangyeolError, HgFileType, HgStatus};

use error::{clear_last_error, last_error_c_str, set_last_error};
use rhwp::document_core::DocumentCore;
use rhwp::error::HwpError;
use rhwp::model::control::Control;
use rhwp::model::document::Document;
use rhwp::model::paragraph::Paragraph;
use rhwp::parser::{detect_format, FileFormat};
use std::ffi::{c_char, CStr};
use std::panic::{self, AssertUnwindSafe};
use std::path::Path;
use std::ptr;
use std::slice;
use std::sync::Mutex;

/// Opaque session pointer type for the C ABI (`typedef struct hg_engine hg_engine`).
#[allow(non_camel_case_types)]
pub struct hg_engine {
    core: DocumentCore,
}

struct AllocBuf {
    bytes: Vec<u8>,
}

static BUFFERS: Mutex<Vec<AllocBuf>> = Mutex::new(Vec::new());

fn fail(err: HangyeolError) -> HgStatus {
    set_last_error(err);
    err.status()
}

fn ok() -> HgStatus {
    clear_last_error();
    HgStatus::Ok
}

/// Map rhwp open failures onto Hangyeol freeze codes.
///
/// Truncated / unknown / malformed containers become **CORRUPT** (F16),
/// not a vague `UNSUPPORTED_FILE_FORMAT` passthrough.
pub fn map_open_format(format: FileFormat) -> Result<(), HangyeolError> {
    match format {
        FileFormat::Hwp | FileFormat::Hwpx => Ok(()),
        FileFormat::Hwp3 | FileFormat::Hml => Err(HangyeolError::UnsupportedVersion),
        FileFormat::DrmProtected => Err(HangyeolError::UnsupportedVersion),
        FileFormat::Empty | FileFormat::Unknown => Err(HangyeolError::Corrupt),
    }
}

fn map_open_hwp_error(err: HwpError) -> HangyeolError {
    let msg = err.to_string();
    if msg.contains("EncryptedDocument")
        || msg.contains("비밀번호")
        || msg.contains("암호 문서")
        || msg.contains("암호화된 문서")
    {
        return HangyeolError::Encrypted;
    }
    if msg.contains("UNSUPPORTED_HWP3") || msg.contains("HWP 3.0") || msg.contains("UNSUPPORTED_HML")
    {
        return HangyeolError::UnsupportedVersion;
    }
    if msg.contains("DRM_PROTECTED") {
        return HangyeolError::UnsupportedVersion;
    }
    // Includes UNSUPPORTED_FILE_FORMAT (truncated ZIP / unknown magic) → CORRUPT.
    HangyeolError::Corrupt
}

/// Verified Hangyeol clear-before-save recipe (hub-A gate):
/// after `replace_all_native`, walk `document_mut` **sections / paras /
/// table cell paras** and `line_segs.clear()`, then `export_hwpx_native`.
/// Default rhwp export leaves `hp:linesegarray`.
pub fn clear_all_line_segs(core: &mut DocumentCore) {
    let document = core.document_mut();
    for section in &mut document.sections {
        for para in &mut section.paragraphs {
            para.line_segs.clear();
            for control in &mut para.controls {
                if let Control::Table(table) = control {
                    for cell in &mut table.cells {
                        for cell_para in &mut cell.paragraphs {
                            cell_para.line_segs.clear();
                        }
                    }
                }
            }
        }
    }
}

fn collect_plain_text(document: &Document) -> String {
    let mut out = String::new();
    for section in &document.sections {
        for para in &section.paragraphs {
            append_para_text(para, &mut out);
        }
    }
    out
}

fn append_para_text(para: &Paragraph, out: &mut String) {
    let trimmed = para.text.trim();
    if !trimmed.is_empty() {
        if !out.is_empty() {
            out.push('\n');
        }
        out.push_str(trimmed);
    }
    for control in &para.controls {
        if let Control::Table(table) = control {
            for cell in &table.cells {
                for cell_para in &cell.paragraphs {
                    append_para_text(cell_para, out);
                }
            }
        }
    }
}

fn parse_replace_count(json: &str) -> usize {
    let Some(rest) = json.split("\"count\":").nth(1) else {
        return 0;
    };
    rest.chars()
        .take_while(|c| c.is_ascii_digit())
        .collect::<String>()
        .parse()
        .unwrap_or(0)
}

/// `hg_save_hwpx` / Kit `hg_save(HWPX)`: the verified recipe, then serialize.
fn export_hwpx_cleared(core: &mut DocumentCore) -> Result<Vec<u8>, HangyeolError> {
    clear_all_line_segs(core);
    core.export_hwpx_native()
        .map_err(|_| HangyeolError::SaveRejected)
}

fn leak_buffer(mut bytes: Vec<u8>) -> (*mut u8, usize) {
    if bytes.is_empty() {
        bytes.push(0);
        let ptr = {
            let mut guard = BUFFERS.lock().expect("buffer lock");
            guard.push(AllocBuf { bytes });
            guard.last_mut().unwrap().bytes.as_mut_ptr()
        };
        return (ptr, 0);
    }
    let len = bytes.len();
    let mut guard = BUFFERS.lock().expect("buffer lock");
    guard.push(AllocBuf { bytes });
    let ptr = guard.last_mut().unwrap().bytes.as_mut_ptr();
    (ptr, len)
}

fn take_engine<'a>(ptr: *mut hg_engine) -> Result<&'a mut hg_engine, HangyeolError> {
    if ptr.is_null() {
        return Err(HangyeolError::Corrupt);
    }
    Ok(unsafe { &mut *ptr })
}

fn c_str<'a>(ptr: *const c_char) -> Result<&'a str, HangyeolError> {
    if ptr.is_null() {
        return Err(HangyeolError::Corrupt);
    }
    unsafe { CStr::from_ptr(ptr) }
        .to_str()
        .map_err(|_| HangyeolError::Corrupt)
}

fn write_out_engine(out: *mut *mut hg_engine, value: *mut hg_engine) {
    if !out.is_null() {
        unsafe {
            *out = value;
        }
    }
}

fn write_out_buf(out_bytes: *mut *mut u8, out_len: *mut usize, bytes: *mut u8, len: usize) {
    if !out_bytes.is_null() {
        unsafe {
            *out_bytes = bytes;
        }
    }
    if !out_len.is_null() {
        unsafe {
            *out_len = len;
        }
    }
}

fn open_bytes_inner(bytes: &[u8]) -> Result<DocumentCore, HangyeolError> {
    map_open_format(detect_format(bytes))?;
    DocumentCore::from_bytes(bytes).map_err(map_open_hwp_error)
}

fn ffi_status(f: impl FnOnce() -> Result<HgStatus, HangyeolError>) -> HgStatus {
    match panic::catch_unwind(AssertUnwindSafe(f)) {
        Ok(Ok(status)) => status,
        Ok(Err(err)) => fail(err),
        Err(_) => fail(HangyeolError::Corrupt),
    }
}

/// Open HWP/HWPX bytes via `DocumentCore::from_bytes` (extension-agnostic).
pub fn open_bytes(bytes: &[u8]) -> Result<DocumentCore, HangyeolError> {
    open_bytes_inner(bytes)
}

/// Plain text from IR body + table cells (no renderer).
pub fn plain_text(core: &DocumentCore) -> String {
    collect_plain_text(core.document())
}

/// `replace_all_native` including table cells. Returns replacement count.
pub fn replace_text(core: &mut DocumentCore, find: &str, replace: &str) -> Result<usize, HangyeolError> {
    if find.is_empty() {
        return Ok(0);
    }
    let json = core
        .replace_all_native(find, replace, true)
        .map_err(|_| HangyeolError::Corrupt)?;
    Ok(parse_replace_count(&json))
}

/// Clear `line_segs` then `export_hwpx_native`.
pub fn save_hwpx_bytes(core: &mut DocumentCore) -> Result<Vec<u8>, HangyeolError> {
    export_hwpx_cleared(core)
}

fn parse_file_type(file_type: i32) -> Result<HgFileType, HangyeolError> {
    match file_type {
        0 => Ok(HgFileType::Hwpx),
        1 => Ok(HgFileType::Hwp),
        _ => Err(HangyeolError::UnsupportedVersion),
    }
}

#[no_mangle]
pub unsafe extern "C" fn hg_open(
    bytes: *const u8,
    length: usize,
    _type: i32,
    out_engine: *mut *mut hg_engine,
) -> HgStatus {
    ffi_status(|| {
        write_out_engine(out_engine, ptr::null_mut());
        if out_engine.is_null() {
            return Err(HangyeolError::Corrupt);
        }
        // `_type` is Kit ABI only. Format is detected from bytes (F14).
        let _ = parse_file_type(_type);
        if bytes.is_null() && length != 0 {
            return Err(HangyeolError::Corrupt);
        }
        let slice = if length == 0 {
            &[][..]
        } else {
            unsafe { slice::from_raw_parts(bytes, length) }
        };
        let core = open_bytes_inner(slice)?;
        let engine = Box::into_raw(Box::new(hg_engine { core }));
        write_out_engine(out_engine, engine);
        Ok(ok())
    })
}

#[no_mangle]
pub unsafe extern "C" fn hg_save(
    engine: *mut hg_engine,
    file_type: i32,
    out_bytes: *mut *mut u8,
    out_length: *mut usize,
) -> HgStatus {
    ffi_status(|| {
        write_out_buf(out_bytes, out_length, ptr::null_mut(), 0);
        if parse_file_type(file_type)? != HgFileType::Hwpx {
            return Err(HangyeolError::SaveRejected);
        }
        let engine = take_engine(engine)?;
        let bytes = export_hwpx_cleared(&mut engine.core)?;
        let (ptr, len) = leak_buffer(bytes);
        write_out_buf(out_bytes, out_length, ptr, len);
        Ok(ok())
    })
}

#[no_mangle]
pub unsafe extern "C" fn hg_free_buffer(bytes: *mut u8) {
    if bytes.is_null() {
        return;
    }
    let mut guard = match BUFFERS.lock() {
        Ok(g) => g,
        Err(poison) => poison.into_inner(),
    };
    if let Some(idx) = guard.iter().position(|b| b.bytes.as_ptr() == bytes) {
        guard.swap_remove(idx);
    }
}

#[no_mangle]
pub unsafe extern "C" fn hg_close(engine: *mut hg_engine) {
    if engine.is_null() {
        return;
    }
    drop(unsafe { Box::from_raw(engine) });
}

#[no_mangle]
pub unsafe extern "C" fn hg_plain_text(
    engine: *mut hg_engine,
    out_bytes: *mut *mut u8,
    out_length: *mut usize,
) -> HgStatus {
    ffi_status(|| {
        write_out_buf(out_bytes, out_length, ptr::null_mut(), 0);
        let engine = take_engine(engine)?;
        let text = collect_plain_text(engine.core.document());
        let (ptr, len) = leak_buffer(text.into_bytes());
        write_out_buf(out_bytes, out_length, ptr, len);
        Ok(ok())
    })
}

#[no_mangle]
pub unsafe extern "C" fn hg_replace_text(
    engine: *mut hg_engine,
    find: *const c_char,
    replace: *const c_char,
    out_count: *mut usize,
) -> HgStatus {
    ffi_status(|| {
        if !out_count.is_null() {
            unsafe {
                *out_count = 0;
            }
        }
        let engine = take_engine(engine)?;
        let find = c_str(find)?;
        let replace = c_str(replace)?;
        let count = replace_text(&mut engine.core, find, replace)?;
        if !out_count.is_null() {
            unsafe {
                *out_count = count;
            }
        }
        Ok(ok())
    })
}

/// Freeze `hg_save_hwpx`: same clear-before-save as Kit `hg_save` (HWPX).
/// Sequence: walk `document_mut` sections/paras/table cell paras →
/// `line_segs.clear()` → `export_hwpx_native`.
#[no_mangle]
pub unsafe extern "C" fn hg_save_hwpx(engine: *mut hg_engine, path: *const c_char) -> HgStatus {
    ffi_status(|| {
        let engine = take_engine(engine)?;
        let path = Path::new(c_str(path)?);
        let bytes = export_hwpx_cleared(&mut engine.core)?;
        if let Some(parent) = path.parent() {
            if !parent.as_os_str().is_empty() {
                std::fs::create_dir_all(parent).map_err(|_| HangyeolError::SaveRejected)?;
            }
        }
        std::fs::write(path, bytes).map_err(|_| HangyeolError::SaveRejected)?;
        Ok(ok())
    })
}

#[no_mangle]
pub unsafe extern "C" fn hg_insert_text(
    engine: *mut hg_engine,
    section: u32,
    paragraph: u32,
    char_offset: u32,
    text: *const c_char,
) -> HgStatus {
    ffi_status(|| {
        let engine = take_engine(engine)?;
        let text = c_str(text)?;
        engine
            .core
            .insert_text_native(section as usize, paragraph as usize, char_offset as usize, text)
            .map_err(|_| HangyeolError::Corrupt)?;
        Ok(ok())
    })
}

#[no_mangle]
pub unsafe extern "C" fn hg_delete_range(
    engine: *mut hg_engine,
    section: u32,
    paragraph: u32,
    char_offset: u32,
    count: u32,
) -> HgStatus {
    ffi_status(|| {
        let engine = take_engine(engine)?;
        engine
            .core
            .delete_text_native(
                section as usize,
                paragraph as usize,
                char_offset as usize,
                count as usize,
            )
            .map_err(|_| HangyeolError::Corrupt)?;
        Ok(ok())
    })
}

#[no_mangle]
pub extern "C" fn hg_last_error() -> *const c_char {
    last_error_c_str()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Read;

    fn hub_a() -> Vec<u8> {
        let path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../fixtures/hub_hwpxlib_SimpleTable.hwpx");
        std::fs::read(path).expect("hub-A")
    }

    fn count_linesegarray(hwpx: &[u8]) -> usize {
        let mut archive = zip::ZipArchive::new(std::io::Cursor::new(hwpx)).unwrap();
        let mut total = 0usize;
        for i in 0..archive.len() {
            let mut file = archive.by_index(i).unwrap();
            if !file.name().ends_with(".xml") {
                continue;
            }
            let mut xml = String::new();
            file.read_to_string(&mut xml).unwrap();
            total += xml.matches("hp:linesegarray").count();
        }
        total
    }

    #[test]
    fn unknown_format_is_corrupt_not_unsupported() {
        assert_eq!(map_open_format(FileFormat::Unknown), Err(HangyeolError::Corrupt));
        assert_eq!(map_open_format(FileFormat::Empty), Err(HangyeolError::Corrupt));
        assert_eq!(
            map_open_format(FileFormat::Hwp3),
            Err(HangyeolError::UnsupportedVersion)
        );
        assert_eq!(HangyeolError::Encrypted.status(), HgStatus::Password);
        assert_eq!(HangyeolError::SaveRejected.status(), HgStatus::Unsupported);
        assert_eq!(HangyeolError::Corrupt.status(), HgStatus::Corrupt);
    }

    /// Exact verified recipe on DocumentCore (not ZIP/XML edit):
    /// replace_all_native → document_mut sections/paras/table cell paras
    /// `line_segs.clear()` → export_hwpx_native.
    #[test]
    fn document_core_clear_before_save_recipe() {
        let bytes = hub_a();
        assert!(count_linesegarray(&bytes) > 0);

        let mut core = DocumentCore::from_bytes(&bytes).expect("open hub-A");
        core.replace_all_native("1", "HGPOC99", true)
            .expect("replace_all_native");

        {
            let document = core.document_mut();
            for section in &mut document.sections {
                for para in &mut section.paragraphs {
                    para.line_segs.clear();
                    for control in &mut para.controls {
                        if let Control::Table(table) = control {
                            for cell in &mut table.cells {
                                for cell_para in &mut cell.paragraphs {
                                    cell_para.line_segs.clear();
                                }
                            }
                        }
                    }
                }
            }
        }

        let exported = core.export_hwpx_native().expect("export_hwpx_native");
        assert_eq!(count_linesegarray(&exported), 0, "hp:linesegarray must be 0");

        let reopened = DocumentCore::from_bytes(&exported).expect("reopen");
        let text = collect_plain_text(reopened.document());
        assert!(
            text.contains("HGPOC99"),
            "replacement token must survive export, got {text:?}"
        );
    }
}
