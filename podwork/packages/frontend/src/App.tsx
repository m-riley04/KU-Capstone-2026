// src/App.tsx
import { useCallback, useEffect, useState } from 'react';
import './styles/base.css';
import './styles/layout.css';
import './styles/components.css';
import { SUB_CATEGORY_DATA } from './utilities/sub_categories';
import { DATA_SOURCE } from './utilities/main_categories'
import LoginPage from './LoginPage';
import { getSlideClass, getSelectedNames } from './utilities/helpers';
import { savePreferencesToDatabase } from './services/api';

type CategoryName = keyof typeof DATA_SOURCE;

function App() {
// useStates to keep track of categories being displayed on the screen
  const [activeCategory, setActiveCategory] = useState<CategoryName | null>(null);
  const [activeSubCategory, setActiveSubCategory] = useState<string | null>(null);
  // search state
  const [searchQuery, setSearchQuery] = useState("");
  // keep track of things that are checkmnarked
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  // keep track of what is actually sent to database
  const [savedIds, setSavedIds] = useState<string[]>([])
  // state for toast notification
  const [toast, setToast] = useState<{ message: string, type: 'success' | 'error' } | null>(null);

  const [isLoggedIn, setIsLoggedIn] = useState(() => {
    // check if token exists so a logged in user can stay logged in
    return localStorage.getItem('polypod_userId') !== null;
  });

  // state to hold if the user selected preference summary 
  const [isSummaryOpen, setIsSummaryOpen] = useState(false);

  // when user logs in pull up their saved preferences
  useEffect(() => {
    if (isLoggedIn) {
      const cachedInterests = localStorage.getItem('polypod_interests');

      if (cachedInterests) {
        const parsedInterests = JSON.parse(cachedInterests);
        const interestNames = parsedInterests.map((item: { name: string}) => item.name);

        setSelectedIds(interestNames);
        setSavedIds(interestNames);
      }
    }
  }, [isLoggedIn]); // run whenever a log in status changes

  // auto save
  useEffect(() => {
    // if on level 1 (activeCategory is null) and there are changes to save
    if (activeCategory === null && hasUnsavedChanges()) {
      handleSavePreferences();
    }
  }, [activeCategory, selectedIds, savedIds]);

  // toggle item on/off
  const toggleSelection = useCallback((id: string) => {
    setSelectedIds(prev => {
      if (prev.includes(id)) {
        return prev.filter(itemId => itemId !== id);
      } 
      return [...prev, id];
    });
  }, []);

  // logout user from session
  const handleLogout = () => {
    localStorage.removeItem('polypod_userId'); //remove userID
    setIsLoggedIn(false);
  }

  // check if user has made changes to their preferences
  const hasUnsavedChanges = () => {
    // if they have different number of items then it is a change
    if (selectedIds.length !== savedIds.length) return true;

    // sort both arrays alphabetically so order doesn't matter then compare
    const sortedSelected = [...selectedIds].sort().join(',');
    const sortedSaved = [...savedIds].sort().join(',');

    return sortedSelected !== sortedSaved;
  };

  // trigger the toast and hide it after 3 seconds
  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    
    setTimeout(() => {
      setToast(null);
    }, 3000);
  };

  // function to send preferences to the backend
  const handleSavePreferences = async () => {
    const userId = localStorage.getItem('polypod_userId');

    if (!userId) {
      return;
    }

    try {
      const response = await savePreferencesToDatabase(userId, selectedIds);

      if (response.ok){
        //maybe add small notification that it was saved
        console.log("Successfully saved preferences")
        setSavedIds([...selectedIds]);

        const formattedInterests = selectedIds.map(name => ({name: name}));
        localStorage.setItem('polypod_interests', JSON.stringify(formattedInterests))
        showToast('Preferences auto-saved ✓', 'success');
      }else{
        showToast('Failed to save preferences', 'error');
        console.error('Failed to save preferences.');
      }
    }catch (error){
      showToast('Server not responding', 'error');
      console.error('Server not responding')
    }
  }

  // show login page if not logged in
  if (!isLoggedIn) {
    return <LoginPage onLogin={() => setIsLoggedIn(true)} />;
  }

  return (
    <div className='app-container'>
      <header className='hero'>
        <h1>Polywork</h1>
      </header>

      <button className='logout' onClick={handleLogout}>Sign Out</button>

      {/* sliding window */}
      <div className='slider-viewport'>
        <div className={`slider-track ${getSlideClass(activeCategory, activeSubCategory)}`}>

          {/* level 1 */}
          <div className='slide-page'>
            <h2> Select a Category </h2>
            <div className='menu-grid'>
              {Object.keys(DATA_SOURCE).map((cat) => (
                <button key={cat}
                className='category-card'
                onClick={() => setActiveCategory(cat as CategoryName)}>
                  <span className='cat-name'>{cat}</span>
                  <span className='arrow'>→</span>
                </button>
              ))}
            </div>

            {/* show whats active */}
            <div className='summary-box' onClick={() => setIsSummaryOpen(true)}>
              <h3>Currently Active</h3>
              <p>{selectedIds.length} preferences selected</p>
              <small>(Click to view selected preferences)</small>
            </div>
          </div>

          {/* level 2 */}
          <div className='slide-page'>
            <button className='back-btn' onClick={() => setActiveCategory(null)}>
            ← Back to Categories
            </button>

            <h2>{activeCategory} Options</h2>

            <div className='interest-list'>
              {activeCategory && DATA_SOURCE[activeCategory].map((item) => {
                const hasChildren = item.id in SUB_CATEGORY_DATA;
                
                return hasChildren ? (
                  // option 1: is a folder with subcategories -> Show Arrow Button
                  <button 
                    key={item.id} 
                    className='interest-item' 
                    onClick={() => setActiveSubCategory(item.id)}
                    style={{justifyContent: 'space-between', fontWeight: 'bold'}}
                  >
                    <span>{item.id}</span>
                    <span>→</span>
                  </button>
                ) : (
                // option 2: not a folder -> show checkbox
                <label key={item.id} className={`interest-item ${selectedIds.includes(item.id) ? 'active' : ''}`}>
                  <input 
                    type="checkbox" 
                    checked={selectedIds.includes(item.id)}
                    onChange={() => toggleSelection(item.id)}
                  />
                  <span>{item.id}</span>
                </label>
                );
              })}
            </div>
          </div>
          {/* level 3 */}
          <div className='slide-page'>
             <button className='back-btn' onClick={() => {setActiveSubCategory(null); setSearchQuery("")}}>
              {/* Go back to Level 2 */}
              ← Back to {activeCategory}
            </button>
            
            <h2>{activeSubCategory}</h2>

            <input 
            type="text" 
            placeholder={`Search ${activeSubCategory}...`}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="search-bar"
            />

            <div className='interest-list'>
              {activeSubCategory && SUB_CATEGORY_DATA[activeSubCategory]?.filter(item =>
              item.id.toLowerCase().includes(searchQuery.toLowerCase())
              ).map((item) => (
                <label key={item.id} className={`interest-item ${selectedIds.includes(item.id) ? 'active' : ''}`}>
                  <input 
                    type="checkbox" 
                    checked={selectedIds.includes(item.id)}
                    onChange={() => toggleSelection(item.id)}
                  />
                  <span>{item.id}</span>
                </label>
              ))}

              {/* No results in search message */}
              {activeSubCategory && 
               SUB_CATEGORY_DATA[activeSubCategory]?.filter(item => 
                 item.id.toLowerCase().includes(searchQuery.toLowerCase())
               ).length === 0 && (
                 <p className="no-results">No results found for "{searchQuery}"</p>
               )
              }
            </div>
          </div>

        </div>
      </div>
      {/*summary modal */}
      {isSummaryOpen && (
        <div className='summary-modal' onClick={() => setIsSummaryOpen(false)}>
          <div className='summary-modal-content' onClick={(e) => e.stopPropagation()}>
            <h2 style={{ textAlign: 'center' }}>Selected Preferences</h2>

            {selectedIds.length === 0 ? (
              <p>No preferenced selected.</p>
            ) : (
              <ul className='summary-list'>
                {(() => {
                  const {subCategoryNames, weatherNames} = getSelectedNames(selectedIds);
                  return (
                    <>
                      {subCategoryNames.map((name) => (
                        <li key={name} className='preference-list'>
                          <span>{name}</span>
                          <button 
                            className='remove-preference'
                            onClick={() => toggleSelection(name)}
                            aria-label = {`Remove ${name}`}
                            title="Remove preference"
                          >
                            {/* trash can icon from feather icons https://feathericons.com/*/}
                           <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                              <polyline points="3 6 5 6 21 6"></polyline>
                              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                              <line x1="10" y1="11" x2="10" y2="17"></line>
                              <line x1="14" y1="11" x2="14" y2="17"></line>
                            </svg>
                          </button>
                        </li>
                      ))}
                      {weatherNames.map((name) => (
                        <li key={name} className='preference-list'>
                          <button 
                            className='remove-preference'
                            onClick={() => toggleSelection(name)}
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
                          <span>{name}</span>
                        </li>
                      ))}
                    </>
                  )
                })()}
              </ul>
            )}
            <button
              className='save-btn'
              onClick={() => setIsSummaryOpen(false)}
            >
              Close
            </button>
          </div>
        </div>
      )}
      {toast && (
        <div className={`toast-notification ${toast.type}`}>
          {toast.message}
        </div>
      )}
    </div>
    )}


export default App;