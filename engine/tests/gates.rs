//! Hangyeol DocumentCore FFI gates: hub-A replace/insert/delete/table+clear,
//! hub-B image list, F14, F16.

use hangyeol_engine::{
    hg_close, hg_delete_range, hg_engine, hg_free_buffer, hg_insert_text, hg_last_error,
    hg_list_images, hg_list_tables, hg_open, hg_plain_text, hg_replace_text, hg_save, hg_save_hwpx,
    hg_set_cell_text, HangyeolError, HgImageInfo, HgStatus, HgTableInfo,
};
use std::ffi::{CStr, CString};
use std::io::Read;
use std::path::PathBuf;
use std::ptr;

fn fixtures_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../fixtures")
}

fn testdata_out() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("testdata/out")
}

fn read_fixture(name: &str) -> Vec<u8> {
    std::fs::read(fixtures_dir().join(name)).unwrap_or_else(|e| panic!("read {name}: {e}"))
}

fn last_error_str() -> Option<&'static str> {
    let ptr = hg_last_error();
    if ptr.is_null() {
        None
    } else {
        Some(unsafe { CStr::from_ptr(ptr) }.to_str().unwrap())
    }
}

fn count_linesegarray(hwpx: &[u8]) -> usize {
    let mut archive = zip::ZipArchive::new(std::io::Cursor::new(hwpx)).expect("zip");
    let mut total = 0usize;
    for i in 0..archive.len() {
        let mut file = archive.by_index(i).expect("entry");
        if !file.name().ends_with(".xml") {
            continue;
        }
        let mut xml = String::new();
        file.read_to_string(&mut xml).expect("xml");
        total += xml.matches("hp:linesegarray").count();
    }
    total
}

fn utf8_from_buf(ptr: *mut u8, len: usize) -> String {
    assert!(!ptr.is_null());
    let bytes = unsafe { std::slice::from_raw_parts(ptr, len) };
    String::from_utf8(bytes.to_vec()).expect("utf-8")
}

#[test]
fn hub_a_replace_clear_before_save_roundtrip() {
    let bytes = read_fixture("hub_hwpxlib_SimpleTable.hwpx");
    assert!(
        count_linesegarray(&bytes) > 0,
        "hub-A fixture must contain hp:linesegarray so the clear gate is meaningful"
    );

    unsafe {
        let mut engine: *mut hg_engine = ptr::null_mut();
        let status = hg_open(bytes.as_ptr(), bytes.len(), 0, &mut engine);
        assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());

        let find = CString::new("1").unwrap();
        let replace = CString::new("HGPOC99").unwrap();
        let mut count = 0usize;
        let status = hg_replace_text(engine, find.as_ptr(), replace.as_ptr(), &mut count);
        assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
        assert!(
            count >= 1,
            "expected at least one cell-token replacement, got {count}"
        );

        let mut saved_ptr = ptr::null_mut();
        let mut saved_len = 0usize;
        let status = hg_save(engine, 0, &mut saved_ptr, &mut saved_len);
        assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
        let saved = std::slice::from_raw_parts(saved_ptr, saved_len).to_vec();
        hg_free_buffer(saved_ptr);

        assert_eq!(
            count_linesegarray(&saved),
            0,
            "clear-before-save must emit 0 hp:linesegarray"
        );

        let out_dir = testdata_out();
        std::fs::create_dir_all(&out_dir).unwrap();
        let artifact = out_dir.join("SimpleTable-cleared-replaced.hwpx");
        let path = CString::new(artifact.to_str().unwrap()).unwrap();
        let status = hg_save_hwpx(engine, path.as_ptr());
        assert_eq!(status, HgStatus::Ok, "hg_save_hwpx {:?}", last_error_str());
        hg_close(engine);

        let disk = std::fs::read(&artifact).unwrap();
        assert_eq!(count_linesegarray(&disk), 0);

        let mut engine2: *mut hg_engine = ptr::null_mut();
        let status = hg_open(saved.as_ptr(), saved.len(), 0, &mut engine2);
        assert_eq!(status, HgStatus::Ok, "reopen {:?}", last_error_str());
        let mut text_ptr = ptr::null_mut();
        let mut text_len = 0usize;
        let status = hg_plain_text(engine2, &mut text_ptr, &mut text_len);
        assert_eq!(status, HgStatus::Ok);
        let text = utf8_from_buf(text_ptr, text_len);
        hg_free_buffer(text_ptr);
        hg_close(engine2);

        assert!(
            text.contains("HGPOC99"),
            "reopened plain text must contain replacement token, got {text:?}"
        );
    }
}

#[test]
fn f14_wrong_ext_pdf_opens_as_hwpx_by_bytes() {
    let path = fixtures_dir().join("14_wrong_ext_hwpx.pdf");
    assert_eq!(path.extension().and_then(|e| e.to_str()), Some("pdf"));
    let bytes = std::fs::read(&path).unwrap();
    unsafe {
        // Type hint HWP must not matter — detect by bytes.
        let mut engine: *mut hg_engine = ptr::null_mut();
        let status = hg_open(bytes.as_ptr(), bytes.len(), 1, &mut engine);
        assert_eq!(status, HgStatus::Ok, "F14 {:?}", last_error_str());
        assert!(!engine.is_null());
        let mut text_ptr = ptr::null_mut();
        let mut text_len = 0usize;
        assert_eq!(
            hg_plain_text(engine, &mut text_ptr, &mut text_len),
            HgStatus::Ok
        );
        let text = utf8_from_buf(text_ptr, text_len);
        hg_free_buffer(text_ptr);
        hg_close(engine);
        assert!(
            text.contains('1') && text.contains('2'),
            "F14 should extract SimpleTable cells, got {text:?}"
        );
    }
}

#[test]
fn f16_truncated_is_corrupt_not_unsupported() {
    let bytes = read_fixture("16_corrupt_truncated.hwpx");
    unsafe {
        let mut engine: *mut hg_engine = ptr::null_mut();
        let status = hg_open(bytes.as_ptr(), bytes.len(), 0, &mut engine);
        assert!(engine.is_null());
        assert_eq!(
            status,
            HgStatus::Corrupt,
            "F16 must be HG_CORRUPT / CORRUPT, got {status:?} {:?}",
            last_error_str()
        );
        assert_eq!(last_error_str(), Some("CORRUPT"));
        assert_eq!(HangyeolError::Corrupt.as_str(), "CORRUPT");
    }
}

#[test]
fn hwp_save_is_rejected() {
    let bytes = read_fixture("hub_hwpxlib_SimpleTable.hwpx");
    unsafe {
        let mut engine: *mut hg_engine = ptr::null_mut();
        assert_eq!(
            hg_open(bytes.as_ptr(), bytes.len(), 0, &mut engine),
            HgStatus::Ok
        );
        let mut out = ptr::null_mut();
        let mut len = 0usize;
        let status = hg_save(engine, 1, &mut out, &mut len);
        assert_eq!(status, HgStatus::Unsupported);
        assert_eq!(last_error_str(), Some("SAVE_REJECTED"));
        assert!(out.is_null());
        hg_close(engine);
    }
}

#[test]
fn fixture_paths_exist() {
    for name in [
        "hub_hwpxlib_SimpleTable.hwpx",
        "hub_hwpxlib_SimplePicture.hwpx",
        "14_wrong_ext_hwpx.pdf",
        "16_corrupt_truncated.hwpx",
    ] {
        let p = fixtures_dir().join(name);
        assert!(p.is_file(), "missing {p:?}");
    }
}

fn open_hub_a() -> (*mut hg_engine, Vec<u8>) {
    let bytes = read_fixture("hub_hwpxlib_SimpleTable.hwpx");
    let mut engine: *mut hg_engine = ptr::null_mut();
    let status = unsafe { hg_open(bytes.as_ptr(), bytes.len(), 0, &mut engine) };
    assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
    assert!(!engine.is_null());
    (engine, bytes)
}

fn plain_text(engine: *mut hg_engine) -> String {
    let mut text_ptr = ptr::null_mut();
    let mut text_len = 0usize;
    let status = unsafe { hg_plain_text(engine, &mut text_ptr, &mut text_len) };
    assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
    let text = utf8_from_buf(text_ptr, text_len);
    unsafe { hg_free_buffer(text_ptr) };
    text
}

fn save_cleared(engine: *mut hg_engine) -> Vec<u8> {
    let mut saved_ptr = ptr::null_mut();
    let mut saved_len = 0usize;
    let status = unsafe { hg_save(engine, 0, &mut saved_ptr, &mut saved_len) };
    assert_eq!(status, HgStatus::Ok, "hg_save {:?}", last_error_str());
    let saved = unsafe { std::slice::from_raw_parts(saved_ptr, saved_len).to_vec() };
    unsafe { hg_free_buffer(saved_ptr) };
    assert_eq!(
        count_linesegarray(&saved),
        0,
        "clear-before-save must emit 0 hp:linesegarray"
    );
    saved
}

#[test]
fn hub_a_list_tables_set_cell_clear_before_save_roundtrip() {
    unsafe {
        let (engine, _) = open_hub_a();

        let mut count = 0usize;
        let status = hg_list_tables(engine, ptr::null_mut(), 0, &mut count);
        assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
        assert_eq!(count, 1, "SimpleTable / hub-A has one table");

        let mut infos = [HgTableInfo {
            index: 0,
            section: 0,
            paragraph: 0,
            control: 0,
            rows: 0,
            cols: 0,
        }; 4];
        let status = hg_list_tables(engine, infos.as_mut_ptr(), infos.len(), &mut count);
        assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
        assert_eq!(count, 1);
        assert_eq!(infos[0].index, 0);
        assert_eq!(infos[0].rows, 3);
        assert_eq!(infos[0].cols, 3);

        let token = CString::new("HGSET99").unwrap();
        let status = hg_set_cell_text(engine, infos[0].index, 0, 0, token.as_ptr());
        assert_eq!(status, HgStatus::Ok, "set_cell {:?}", last_error_str());

        let before_save = plain_text(engine);
        assert!(
            before_save.contains("HGSET99"),
            "cell text before save, got {before_save:?}"
        );

        let saved = save_cleared(engine);

        let out_dir = testdata_out();
        std::fs::create_dir_all(&out_dir).unwrap();
        let artifact = out_dir.join("SimpleTable-set-cell.hwpx");
        let path = CString::new(artifact.to_str().unwrap()).unwrap();
        let status = hg_save_hwpx(engine, path.as_ptr());
        assert_eq!(status, HgStatus::Ok, "hg_save_hwpx {:?}", last_error_str());
        hg_close(engine);

        let disk = std::fs::read(&artifact).unwrap();
        assert_eq!(count_linesegarray(&disk), 0);

        let mut engine2: *mut hg_engine = ptr::null_mut();
        let status = hg_open(saved.as_ptr(), saved.len(), 0, &mut engine2);
        assert_eq!(status, HgStatus::Ok, "reopen {:?}", last_error_str());
        let text = plain_text(engine2);

        let mut count2 = 0usize;
        let mut infos2 = [HgTableInfo {
            index: 0,
            section: 0,
            paragraph: 0,
            control: 0,
            rows: 0,
            cols: 0,
        }; 1];
        assert_eq!(
            hg_list_tables(engine2, infos2.as_mut_ptr(), 1, &mut count2),
            HgStatus::Ok
        );
        assert_eq!(count2, 1);
        assert_eq!(infos2[0].rows, 3);
        assert_eq!(infos2[0].cols, 3);
        hg_close(engine2);

        assert!(
            text.contains("HGSET99"),
            "reopened plain text must contain set-cell token, got {text:?}"
        );
        assert!(
            text.contains('2') && text.contains('5'),
            "other SimpleTable cells must survive, got {text:?}"
        );
    }
}

#[test]
fn set_cell_text_out_of_range_is_corrupt() {
    unsafe {
        let (engine, _) = open_hub_a();
        let token = CString::new("x").unwrap();
        let status = hg_set_cell_text(engine, 99, 0, 0, token.as_ptr());
        assert_eq!(status, HgStatus::Corrupt);
        assert_eq!(last_error_str(), Some("CORRUPT"));
        let status = hg_set_cell_text(engine, 0, 9, 0, token.as_ptr());
        assert_eq!(status, HgStatus::Corrupt);
        hg_close(engine);
    }
}

fn save_hwpx_cleared(engine: *mut hg_engine, name: &str) -> PathBuf {
    let out_dir = testdata_out();
    std::fs::create_dir_all(&out_dir).unwrap();
    let artifact = out_dir.join(name);
    let path = CString::new(artifact.to_str().unwrap()).unwrap();
    let status = unsafe { hg_save_hwpx(engine, path.as_ptr()) };
    assert_eq!(status, HgStatus::Ok, "hg_save_hwpx {:?}", last_error_str());
    let disk = std::fs::read(&artifact).unwrap();
    assert_eq!(
        count_linesegarray(&disk),
        0,
        "hg_save_hwpx must emit 0 hp:linesegarray"
    );
    artifact
}

fn reopen_plain_text(bytes: &[u8]) -> String {
    let mut engine: *mut hg_engine = ptr::null_mut();
    let status = unsafe { hg_open(bytes.as_ptr(), bytes.len(), 0, &mut engine) };
    assert_eq!(status, HgStatus::Ok, "reopen {:?}", last_error_str());
    let text = plain_text(engine);
    unsafe { hg_close(engine) };
    text
}

/// Product gate: `hg_insert_text` at known hub-A (section 0, para 0, offset 0).
/// `hg_plain_text` shows the token; `hg_save_hwpx` clear-before-save ZIP has
/// **0** `hp:linesegarray`; reopen still contains the token.
#[test]
fn hub_a_insert_text_clear_before_save_roundtrip() {
    unsafe {
        let (engine, _) = open_hub_a();
        let token = CString::new("HGINS99").unwrap();
        let status = hg_insert_text(engine, 0, 0, 0, token.as_ptr());
        assert_eq!(status, HgStatus::Ok, "insert {:?}", last_error_str());

        let before_save = plain_text(engine);
        assert!(
            before_save.contains("HGINS99"),
            "inserted token before save, got {before_save:?}"
        );

        let saved = save_cleared(engine);
        let artifact = save_hwpx_cleared(engine, "SimpleTable-inserted.hwpx");
        hg_close(engine);

        let disk = std::fs::read(&artifact).unwrap();
        assert_eq!(count_linesegarray(&disk), 0);

        let text = reopen_plain_text(&saved);
        assert!(
            text.contains("HGINS99"),
            "reopened plain text must contain inserted token, got {text:?}"
        );
        assert!(
            text.contains('2') && text.contains('5'),
            "other SimpleTable cells must survive, got {text:?}"
        );
    }
}

/// Product gate: `hg_delete_range` of a known hub-A body range (seed token
/// at section 0 / para 0 / offset 0, length 7). `hg_plain_text` must drop
/// the token; `hg_save_hwpx` ZIP has **0** `hp:linesegarray`; reopen stays
/// without the token.
#[test]
fn hub_a_delete_range_clear_before_save_roundtrip() {
    unsafe {
        let (engine, _) = open_hub_a();
        let token = CString::new("HGDEL99").unwrap();
        assert_eq!(
            hg_insert_text(engine, 0, 0, 0, token.as_ptr()),
            HgStatus::Ok,
            "seed {:?}",
            last_error_str()
        );
        assert!(plain_text(engine).contains("HGDEL99"));

        let status = hg_delete_range(engine, 0, 0, 0, 7);
        assert_eq!(status, HgStatus::Ok, "delete {:?}", last_error_str());

        let before_save = plain_text(engine);
        assert!(
            !before_save.contains("HGDEL99"),
            "deleted token must leave plain text, got {before_save:?}"
        );

        let saved = save_cleared(engine);
        let artifact = save_hwpx_cleared(engine, "SimpleTable-deleted.hwpx");
        hg_close(engine);

        let disk = std::fs::read(&artifact).unwrap();
        assert_eq!(count_linesegarray(&disk), 0);

        let text = reopen_plain_text(&saved);
        assert!(
            !text.contains("HGDEL99"),
            "reopened plain text must not contain deleted token, got {text:?}"
        );
        assert!(
            text.contains('2') && text.contains('5'),
            "other SimpleTable cells must survive, got {text:?}"
        );
    }
}

/// Insert/delete failures stay on the freeze four: invalid index → CORRUPT.
#[test]
fn insert_delete_out_of_range_is_corrupt() {
    unsafe {
        let (engine, _) = open_hub_a();
        let token = CString::new("x").unwrap();
        let status = hg_insert_text(engine, 9, 0, 0, token.as_ptr());
        assert_eq!(status, HgStatus::Corrupt);
        assert_eq!(last_error_str(), Some("CORRUPT"));
        let status = hg_delete_range(engine, 0, 99, 0, 1);
        assert_eq!(status, HgStatus::Corrupt);
        assert_eq!(last_error_str(), Some("CORRUPT"));
        hg_close(engine);
    }
}

fn zip_bindata_entries(hwpx: &[u8]) -> Vec<(String, Vec<u8>)> {
    let mut archive = zip::ZipArchive::new(std::io::Cursor::new(hwpx)).expect("zip");
    let mut out = Vec::new();
    for i in 0..archive.len() {
        let mut file = archive.by_index(i).expect("entry");
        let name = file.name().to_string();
        if !name.starts_with("BinData/") {
            continue;
        }
        let mut bytes = Vec::new();
        file.read_to_end(&mut bytes).expect("bindata");
        out.push((name, bytes));
    }
    out.sort_by(|a, b| a.0.cmp(&b.0));
    out
}

fn list_images(engine: *mut hg_engine) -> Vec<HgImageInfo> {
    let mut count = 0usize;
    let status = unsafe { hg_list_images(engine, ptr::null_mut(), 0, &mut count) };
    assert_eq!(status, HgStatus::Ok, "list count {:?}", last_error_str());
    if count == 0 {
        return Vec::new();
    }
    let mut infos = vec![HgImageInfo::zeroed(); count];
    let status = unsafe { hg_list_images(engine, infos.as_mut_ptr(), infos.len(), &mut count) };
    assert_eq!(status, HgStatus::Ok, "list fill {:?}", last_error_str());
    infos.truncate(count);
    infos
}

fn open_hub_b() -> (*mut hg_engine, Vec<u8>) {
    let bytes = read_fixture("hub_hwpxlib_SimplePicture.hwpx");
    let mut engine: *mut hg_engine = ptr::null_mut();
    let status = unsafe { hg_open(bytes.as_ptr(), bytes.len(), 0, &mut engine) };
    assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
    assert!(!engine.is_null());
    (engine, bytes)
}

/// Product gate: hub-B list returns ≥1 image with size/format meta Kit can use.
#[test]
fn hub_b_list_images_has_meta() {
    unsafe {
        let (engine, _) = open_hub_b();
        let mut count = 0usize;
        let status = hg_list_images(engine, ptr::null_mut(), 0, &mut count);
        assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
        assert!(
            count >= 1,
            "hub-B SimplePicture must list ≥1 image, got {count}"
        );

        let mut infos = vec![HgImageInfo::zeroed(); count.max(1)];
        let status = hg_list_images(engine, infos.as_mut_ptr(), infos.len(), &mut count);
        assert_eq!(status, HgStatus::Ok, "{:?}", last_error_str());
        assert!(count >= 1);
        let img = &infos[0];
        assert_eq!(img.index, 0);
        assert!(
            img.width > 0 && img.height > 0,
            "size meta width={} height={}",
            img.width,
            img.height
        );
        let fmt = img.format_str();
        assert!(
            matches!(fmt, "jpg" | "jpeg" | "png" | "gif" | "bmp"),
            "format meta {fmt:?}"
        );
        assert!(
            img.bin_data_id > 0 || !img.href_str().is_empty(),
            "Kit addressing needs bin_data_id or href"
        );
        hg_close(engine);
    }
}

/// Measurement (not a keep-on-save product gate): hub-B open → plain_text
/// (no-op edit) → `hg_save_hwpx` clear-before-save → reopen. Reports whether
/// ZIP `BinData/` binary + count survive. Week-6 approval required to productize.
#[test]
fn hub_b_image_clear_before_save_roundtrip_measurement() {
    unsafe {
        let (engine, original) = open_hub_b();
        let before = list_images(engine);
        assert!(
            !before.is_empty(),
            "measurement needs ≥1 listed image on open"
        );
        let original_bins = zip_bindata_entries(&original);
        assert!(
            !original_bins.is_empty(),
            "hub-B fixture must contain BinData/"
        );

        // Optional no-op: exercise plain_text only. No image-keep experiment.
        let _ = plain_text(engine);

        let saved = save_cleared(engine);
        let artifact = save_hwpx_cleared(engine, "SimplePicture-cleared.hwpx");
        hg_close(engine);

        let disk = std::fs::read(&artifact).unwrap();
        assert_eq!(count_linesegarray(&disk), 0);

        let saved_bins = zip_bindata_entries(&saved);
        let count_preserved = saved_bins.len() == original_bins.len() && !saved_bins.is_empty();
        let binary_preserved = count_preserved
            && saved_bins
                .iter()
                .zip(original_bins.iter())
                .all(|(a, b)| a.0 == b.0 && a.1 == b.1);

        let mut engine2: *mut hg_engine = ptr::null_mut();
        let status = hg_open(saved.as_ptr(), saved.len(), 0, &mut engine2);
        assert_eq!(status, HgStatus::Ok, "reopen {:?}", last_error_str());
        let after = list_images(engine2);
        hg_close(engine2);

        let list_count_preserved = after.len() == before.len();
        eprintln!(
            "hub-B image round-trip measurement (clear-before-save, no keep-on-save experiment):\n\
             - original BinData entries: {}\n\
             - saved BinData entries: {}\n\
             - ZIP binary/count preserved: {}\n\
             - hg_list_images count before/after: {}/{}\n\
             - list count preserved: {}",
            original_bins.len(),
            saved_bins.len(),
            if binary_preserved { "YES" } else { "NO" },
            before.len(),
            after.len(),
            if list_count_preserved { "YES" } else { "NO" }
        );
        // Intentionally no assert on binary preserve — week-6 product decision.
        let _ = (binary_preserved, list_count_preserved);
    }
}
