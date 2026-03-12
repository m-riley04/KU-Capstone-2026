// ProfileBadge.tsx
// Displays the user's avatar, username, ID, and logout button

interface ProfileBadgeProps {
  user: { id: string | number; username: string } | null;
  onLogout: () => void; // when user clicks sign out button
}

function ProfileBadge({ user, onLogout }: ProfileBadgeProps) {
  // don't render until user data is available
  if (!user) return null;

  return (
    <div className="profile-badge">
      {/* shows first letter of username */}
      <div className="avatar">
        {user.username?.charAt(0).toUpperCase() || "?"}
      </div>
      <div className="user-info">
        <span className="username">{user.username || "Unknown"}</span>
        <span className="user-id">ID: #{user.id}</span>
      </div>

      {/* logout button that calls onLogout */}
      <button
        className="badge-logout-btn"
        onClick={onLogout}
        title="Sign Out"
        aria-label="Sign Out"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
          <polyline points="16 17 21 12 16 7"></polyline>
          <line x1="21" y1="12" x2="9" y2="12"></line>
        </svg>
      </button>
    </div>
  );
}

export default ProfileBadge;