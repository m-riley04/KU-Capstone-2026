// src/App.tsx
import { useState } from 'react';
import './App.css';

const DATA_SOURCE = {
  Sports: [
    {id: "NFL"}, 
    {id: "NBA"}, 
    {id: "MLB"}
  ],
  Finance: [
    {id: "Stocks"},
    {id: "Crypto"}
  ],
  Weather: [
    {id: "Rain"},
    {id: "Snow"}, 
    {id: "Heat"}
  ]
}

const DATA_SOURCE_SPORTS: Record<string, {id: string}[]> = {
  NBA: [
    {id: "Atlanta Hawks"},
    {id: "Boston Celtics"},
    {id: "Brooklyn Nets"},
    {id: "Charlotte Hornets"},
    {id: "Chicago Bulls"},
    {id: "Cleveland Cavaliers"},
    {id: "Dallas Mavericks"},
    {id: "Denver Nuggets"},
    {id: "Detroit Pistons"},
    {id: "Golden State Warriors"},
    {id: "Houston Rockets"},
    {id: "Indiana Pacers"},
    {id: "LA Clippers"},
    {id: "Los Angeles Lakers"},
    {id: "Memphis Grizzlies"},
    {id: "Miami Heat"},
    {id: "Milwaukee Bucks"},
    {id: "Minnesota Timberwolves"},
    {id: "New Orleans Pelicans"},
    {id: "New York Knicks"},
    {id: "Oklahoma City Thunder"},
    {id: "Orlando Magic"},
    {id: "Philadelphia 76ers"},
    {id: "Phoenix Suns"},
    {id: "Portland Trail Blazers"},
    {id: "Sacramento Kings"},
    {id: "San Antonio Spurs"},
    {id: "Toronto Raptors"},
    {id: "Utah Jazz"},
    {id: "Washington Wizards"}
    ]
}

type CategoryName = keyof typeof DATA_SOURCE;

function App() {
// useStates to keep track of categories being displayed on the screen
  const [activeCategory, setActiveCategory] = useState<CategoryName | null>(null);
  const [activeSubCategory, setActiveSubCategory] = useState<string | null>(null);
  
  // keep track of things that are checkmnarked
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  // toggle item on/off
  const toggleSelection = (id: string) => {
    if (selectedIds.includes(id)) {
      setSelectedIds(selectedIds.filter(itemId => itemId !== id));
    } else {
      setSelectedIds([...selectedIds, id]); 
    }
  };

  // calculate which "level" we are on for CSS
  const getSlideClass = () => {
    if (activeSubCategory) return 'level-3';
    if (activeCategory) return 'level-2';
    return '';    
  };

  return (
    <div className='app-container'>
      <header className='hero'>
        <h1>Polypod</h1>
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
                const hasChildren = item.id in DATA_SOURCE_SPORTS;
                
                return hasChildren ? (
                  // option 1: is a folder with subcategories -> Show Arrow Button
                  <button 
                    key={item.id} 
                    className='interest-item' 
                    onClick={() => setActiveSubCategory(item.id)}
                    style={{justifyContent: 'space-between', fontWeight: 'bold'}}
                  >
                    <span>{item.id} Teams</span>
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
             <button className='back-btn' onClick={() => setActiveSubCategory(null)}>
              {/* Go back to Level 2 */}
              ← Back to {activeCategory}
            </button>
            <h2>Select {activeSubCategory} Teams</h2>

            <div className='interest-list'>
              {activeSubCategory && DATA_SOURCE_SPORTS[activeSubCategory]?.map((team) => (
                <label key={team.id} className={`interest-item ${selectedIds.includes(team.id) ? 'active' : ''}`}>
                  <input 
                    type="checkbox" 
                    checked={selectedIds.includes(team.id)}
                    onChange={() => toggleSelection(team.id)}
                  />
                  <span>{team.id}</span>
                </label>
              ))}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

export default App;