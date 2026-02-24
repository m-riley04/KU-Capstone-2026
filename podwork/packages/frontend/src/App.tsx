// src/App.tsx
import { useCallback, useState } from 'react';
import './styles/base.css';
import './styles/layout.css';
import './styles/components.css';
import { SUB_CATEGORY_DATA } from './utilities/sub_categories';
import { DATA_SOURCE } from './utilities/main_categories'
import LoginPage from './LoginPage';

type CategoryName = keyof typeof DATA_SOURCE;

function App() {
// useStates to keep track of categories being displayed on the screen
  const [activeCategory, setActiveCategory] = useState<CategoryName | null>(null);
  const [activeSubCategory, setActiveSubCategory] = useState<string | null>(null);
  // search state
  const [searchQuery, setSearchQuery] = useState("");
  // keep track of things that are checkmnarked
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  const [isLoggedIn, setIsLoggedIn] = useState(() => {
    //check if token exists so a logged in user can stay logged in
    return localStorage.getItem('polypod_token') !== null;
  });

  //state to hold if the user selected preference summary 
  const [isSummaryOpen, setIsSummaryOpen] = useState(false);

  // toggle item on/off
  const toggleSelection = useCallback((id: string) => {
    setSelectedIds(prev => {
      if (prev.includes(id)) {
        return prev.filter(itemId => itemId !== id);
      } 
      return [...prev, id];
    });
  }, []);

  // calculate which "level" we are on for CSS
  const getSlideClass = () => {
    if (activeSubCategory) return 'level-3';
    if (activeCategory) return 'level-2';
    return '';    
  };

  const handleLogout = () => {
    localStorage.removeItem('polypod_token'); //remove toke
    setIsLoggedIn(false);
  }

  const handleSavePreferences = async () => {
    const payload = {
      preferences: selectedIds //the entire array of things the user has selected
    }

    try {
      const response = await fetch('http://localhost:3000/api/preferences', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `${localStorage.getItem('polypod_token')}` // send the active users token to keep track of whos preferences these are
        },
        body: JSON.stringify(payload),
      });

      if (response.ok){
        alert('Preferences successfully sent to server');
      }else{
        alert('Failed to save preferences.');
      }
    }catch (error){
      alert('Server not responding')
    }
  }

  // show login page if not logged in
  if (!isLoggedIn) {
    return <LoginPage onLogin={() => setIsLoggedIn(true)} />;
  }

  const getSelectedNames = () => {
    const subCategoryNames: string[] = [];
    const weatherNames: string[] = [];
    
    Object.values(SUB_CATEGORY_DATA).forEach(element => {
      element.forEach((item) => {
        if (selectedIds.includes(item.id)){
          subCategoryNames.push(item.id);
        }
      })
    });
    Object.values(DATA_SOURCE['Weather']).forEach(element => {
        if (selectedIds.includes(element.id)){
          weatherNames.push(element.id);
        }
      });

    return {subCategoryNames, weatherNames};
  }

  return (
    <div className='app-container'>
      <header className='hero'>
        <h1>Polywork</h1>
      </header>

      <button className='logout' onClick={handleLogout}>Sign Out</button>

      {/* sliding window */}
      <div className='slider-viewport'>
        <div className={`slider-track ${getSlideClass()}`}>

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
            <button
            className='save-btn'
            onClick={handleSavePreferences}>
              Save Preferences
            </button>
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
            <h2>Selected Preferences</h2>

            {selectedIds.length === 0 ? (
              <p>No preferenced selected.</p>
            ) : (
              <ul className='summary-list'>
                {getSelectedNames().subCategoryNames.map((name) => (
                  <li key={name}>{name}</li>
                ))}
                {getSelectedNames().weatherNames.map((name) => (
                  <li key={name}>{name}</li>
                ))}
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
    </div>
    )}


export default App;