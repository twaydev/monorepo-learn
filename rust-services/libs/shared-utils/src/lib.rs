use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: i64,
    pub email: String,
    pub name: String,
}

impl User {
    pub fn new(id: i64, email: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            id,
            email: email.into(),
            name: name.into(),
        }
    }
}

#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("Not found: {0}")]
    NotFound(String),
    #[error("Invalid input: {0}")]
    InvalidInput(String),
    #[error("Internal error: {0}")]
    Internal(String),
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_creation() {
        let user = User::new(1, "test@example.com", "Test User");
        assert_eq!(user.id, 1);
        assert_eq!(user.email, "test@example.com");
        assert_eq!(user.name, "Test User");
    }
}
