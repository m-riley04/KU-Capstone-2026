// CategorySlider.tsx
// Handles the three-level sliding navigation for browsing and selecting interest categories
// Level 1 - Top level categories
// Level 2 - items within a selected category
// Level 3 - items within a selected subcategory

import { getSlideClass } from '../utilities/helpers';


interface CategorySliderProps {
  dataSource: Record<string, { id: string }[]>; // all interests 
  selectedIds: string[];                        // currently selected preferences IDs
  onToggle: (id: string) => void;               // check/uncheck preference
  activeCategory: string | null;                // open level 2 category
  setActiveCategory: (cat: string | null) => void;
  activeSubCategory: string | null;             // open level 3 subcategory
  setActiveSubCategory: (cat: string | null) => void;
  onSummaryOpen: () => void;                    // open summary modal 
  searchQuery: string;                          // search bar input value
  setSearchQuery: (q: string) => void;          // update search input
}

function CategorySlider({
  dataSource,
  selectedIds,
  onToggle,
  activeCategory,
  setActiveCategory,
  activeSubCategory,
  setActiveSubCategory,
  onSummaryOpen,
  searchQuery,
  setSearchQuery,
}: CategorySliderProps) {
  return (
    <div className='slider-viewport'>
      <div className={`slider-track ${getSlideClass(activeCategory, activeSubCategory)}`}>

        {/* level 1 — main category grid */}
        <div className='slide-page'>
          <h2>Select a Category</h2>
          <div className='menu-grid'>
            {Object.keys(dataSource).map((cat) => (
              <button
                key={cat}
                className='category-card'
                onClick={() => setActiveCategory(cat)}
              >
                <span className='cat-name'>{cat}</span>
                <span className='arrow'>→</span>
              </button>
            ))}
          </div>

          <div className='summary-box' onClick={onSummaryOpen}>
            <h3>Currently Active</h3>
            <p>{selectedIds.length} preferences selected</p>
            <small>(Click to view selected preferences)</small>
          </div>
        </div>

        {/* level 2 — items within a category */}
        <div className='slide-page'>
          <button className='back-btn' onClick={() => {
            setActiveCategory(null);
            setSearchQuery(""); // clera search
          }}>
            ← Back to Categories
          </button>

          <h2>{activeCategory} Options</h2>

          <input
            type="text"
            placeholder={`Search ${activeCategory}...`}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="search-bar"
          />

          <div className='interest-list'>
            {activeCategory && dataSource[activeCategory]
              .filter(item => item.id.toLowerCase().includes(searchQuery.toLowerCase()))
              .map((item) => {
                // check for subcategories
                const hasChildren = item.id in dataSource;

                return hasChildren ? (
                // navigation button if it has subcategories
                  <button
                    key={item.id}
                    className='interest-item'
                    onClick={() => {
                      setActiveSubCategory(item.id);
                      setSearchQuery("");
                    }}
                    style={{ justifyContent: 'space-between', fontWeight: 'bold' }}
                  >
                    <span>{item.id}</span>
                    <span>→</span>
                  </button>
                ) : (
                // checkbox if no subcategories
                  <label key={item.id} className={`interest-item ${selectedIds.includes(item.id) ? 'active' : ''}`}>
                    <input
                      type="checkbox"
                      checked={selectedIds.includes(item.id)}
                      onChange={() => onToggle(item.id)}
                    />
                    <span>{item.id}</span>
                  </label>
                );
              })}

            {activeCategory &&
              dataSource[activeCategory]?.filter(item =>
                item.id.toLowerCase().includes(searchQuery.toLowerCase())
              ).length === 0 && (
                <p className="no-results" style={{ textAlign: 'center', marginTop: '20px' }}>
                  No results found for "{searchQuery}"
                </p>
              )}
          </div>
        </div>

        {/* level 3 — items within a subcategory */}
        <div className='slide-page'>
          <button className='back-btn' onClick={() => {
            setActiveSubCategory(null);
            setSearchQuery("");
          }}>
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
            {/* all items in level 3 have no subcategories so render checkboxes */}
            {activeSubCategory && dataSource[activeSubCategory]?.filter(item =>
              item.id.toLowerCase().includes(searchQuery.toLowerCase())
            ).map((item) => (
              <label key={item.id} className={`interest-item ${selectedIds.includes(item.id) ? 'active' : ''}`}>
                <input
                  type="checkbox"
                  checked={selectedIds.includes(item.id)}
                  onChange={() => onToggle(item.id)}
                />
                <span>{item.id}</span>
              </label>
            ))}

            {activeSubCategory &&
              dataSource[activeSubCategory]?.filter(item =>
                item.id.toLowerCase().includes(searchQuery.toLowerCase())
              ).length === 0 && (
                <p className="no-results">No results found for "{searchQuery}"</p>
              )}
          </div>
        </div>

      </div>
    </div>
  );
}

export default CategorySlider;