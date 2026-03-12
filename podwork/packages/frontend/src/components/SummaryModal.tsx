// SummaryModal.tsx
// Modal overlay showing all currently selected preferences with option to remove them

interface SummaryModalProps {
  selectedIds: string[]; // currently selected preference names
  onToggle: (id: string) => void; // removes a prefernce when trash icon clicked
  onClose: () => void; // close modal 
}

function SummaryModal({ selectedIds, onToggle, onClose }: SummaryModalProps) {
  return (
    <div className='summary-modal' onClick={onClose}>
      {/* stopPropagation prevents clicks inside the card from bubbling up to the backdrop */}
      <div className='summary-modal-content' onClick={(e) => e.stopPropagation()}>
        <h2 style={{ textAlign: 'center' }}>Selected Preferences</h2>

        {selectedIds.length === 0 ? (
          <p style={{ textAlign: 'center' }}>No preferences selected.</p>
        ) : (
          <ul className='summary-list'>
            {selectedIds.map((name) => (
              <li key={name} className='preference-list'>
                <span style={{ flexGrow: 1 }}>{name}</span>
                
                {/* trash icon for removing preferences */}
                <button
                  className='remove-preference'
                  onClick={() => onToggle(name)}
                  aria-label={`Remove ${name}`}
                  title="Remove preference"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="3 6 5 6 21 6"></polyline>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                    <line x1="10" y1="11" x2="10" y2="17"></line>
                    <line x1="14" y1="11" x2="14" y2="17"></line>
                  </svg>
                </button>
              </li>
            ))}
          </ul>
        )}

        <button className='save-btn' onClick={onClose}>
          Close
        </button>
      </div>
    </div>
  );
}

export default SummaryModal;