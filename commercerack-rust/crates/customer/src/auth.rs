//! Authentication helpers

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Session {
    pub cid: i64,
    pub mid: i32,
    pub created_at: i64,
    pub expires_at: i64,
}

impl Session {
    pub fn new(cid: i64, mid: i32, duration_secs: i64) -> Self {
        let now = chrono::Utc::now().timestamp();
        Self {
            cid,
            mid,
            created_at: now,
            expires_at: now + duration_secs,
        }
    }

    pub fn is_valid(&self) -> bool {
        chrono::Utc::now().timestamp() < self.expires_at
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_session_creation() {
        let session = Session::new(1, 1, 3600);
        assert!(session.is_valid());
        assert_eq!(session.cid, 1);
    }

    #[test]
    fn test_session_expiry() {
        let session = Session::new(1, 1, -1);
        assert!(!session.is_valid());
    }
}
