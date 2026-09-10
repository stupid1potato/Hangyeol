//! Hangyeol freeze error codes mapped onto Kit `hg_status`.
//!
//! | Freeze                | Kit              |
//! |-----------------------|------------------|
//! | `ENCRYPTED`           | `HG_PASSWORD`    |
//! | `UNSUPPORTED_VERSION` | `HG_UNSUPPORTED` |
//! | `SAVE_REJECTED`       | `HG_UNSUPPORTED` |
//! | `CORRUPT`             | `HG_CORRUPT`     |

use std::cell::Cell;
use std::ffi::c_char;
use std::fmt;

/// Kit `hg_status` (i32, matching HangyeolKit).
#[repr(i32)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HgStatus {
    Ok = 0,
    Unsupported = 1,
    Corrupt = 2,
    Password = 3,
}

/// Kit `hg_file_type`.
#[repr(i32)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HgFileType {
    Hwpx = 0,
    Hwp = 1,
}

/// Kickoff freeze string codes.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HangyeolError {
    UnsupportedVersion,
    Encrypted,
    Corrupt,
    SaveRejected,
}

impl HangyeolError {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::UnsupportedVersion => "UNSUPPORTED_VERSION",
            Self::Encrypted => "ENCRYPTED",
            Self::Corrupt => "CORRUPT",
            Self::SaveRejected => "SAVE_REJECTED",
        }
    }

    pub const fn status(self) -> HgStatus {
        match self {
            Self::Encrypted => HgStatus::Password,
            Self::UnsupportedVersion | Self::SaveRejected => HgStatus::Unsupported,
            Self::Corrupt => HgStatus::Corrupt,
        }
    }
}

impl fmt::Display for HangyeolError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

impl std::error::Error for HangyeolError {}

thread_local! {
    static LAST: Cell<Option<HangyeolError>> = const { Cell::new(None) };
}

pub fn clear_last_error() {
    LAST.with(|c| c.set(None));
}

pub fn set_last_error(err: HangyeolError) {
    LAST.with(|c| c.set(Some(err)));
}

pub fn last_error() -> Option<HangyeolError> {
    LAST.with(|c| c.get())
}

pub fn last_error_c_str() -> *const c_char {
    match last_error() {
        Some(HangyeolError::UnsupportedVersion) => c"UNSUPPORTED_VERSION".as_ptr(),
        Some(HangyeolError::Encrypted) => c"ENCRYPTED".as_ptr(),
        Some(HangyeolError::Corrupt) => c"CORRUPT".as_ptr(),
        Some(HangyeolError::SaveRejected) => c"SAVE_REJECTED".as_ptr(),
        None => std::ptr::null(),
    }
}
