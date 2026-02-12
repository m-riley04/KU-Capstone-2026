// src/App.tsx
import { useCallback, useState } from 'react';
import './App.css';
import { SUB_CATEGORY_DATA } from './utilities/sub_categories';
import { DATA_SOURCE } from './utilities/main_categories'

type CategoryName = keyof typeof DATA_SOURCE;

function App() {
// useStates to keep track of categories being displayed on the screen
  const [activeCategory, setActiveCategory] = useState<CategoryName | null>(null);
  const [activeSubCategory, setActiveSubCategory] = useState<string | null>(null);
  
  // search state
  const [searchQuery, setSearchQuery] = useState("");
  // keep track of things that are checkmnarked
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

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

  return (
    <div className='app-container'>
      <header className='hero'>
        <h1>Polywork</h1>
      </header>

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
            <div className='summary-box'>
              <h3>Currently Active</h3>
              <p>{selectedIds.length} preferences enabled</p>
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
    </div>
  );
}

export default App;