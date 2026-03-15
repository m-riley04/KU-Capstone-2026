// ToastNotification.tsx
// Displays a brief success or error message at the bottom of the screen

interface ToastNotificationProps {
  // null means to toast notification is active
  toast: { message: string; type: 'success' | 'error' } | null;
}

function ToastNotification({ toast }: ToastNotificationProps) {
  // exit early if nothing to show
  if (!toast) return null;

  return (
    // type is used to control success/error styling
    <div className={`toast-notification ${toast.type}`}>
      {toast.message}
    </div>
  );
}

export default ToastNotification;