/*App.tsx
Main page for the website, after user logs in this file is rendered
Key functionality
- Keep track of which category or screen the user is on
- Keep track of selected preferences
- Log out user
- Auto save changes
- Render user icon, username, and ID
*/

import { useCallback, useEffect, useState } from 'react';
import './styles/base.css';
import './styles/layout.css';
import './styles/components.css';
import LoginPage from './LoginPage';
import { fetchAndParseInterestsXML } from './utilities/helpers';
import { getAvailableInterests, savePreferencesToDatabase } from './services/api';
import ToastNotification from './components/ToastNotification';
import ProfileBadge from './components/ProfileBadge';
import SummaryModal from './components/SummaryModal';
import CategorySlider from './components/CategorySlider';

function App() {
// useStates to keep track of categories being displayed on the screen
  const [activeCategory, setActiveCategory] = useState<string | null>(null);
  const [dataSource, setDataSource] = useState<Record<string, { id: string }[]>>({});
  const [activeSubCategory, setActiveSubCategory] = useState<string | null>(null);
  // search state
  const [searchQuery, setSearchQuery] = useState("");
  // keep track of things that are checkmnarked
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  // keep track of what is actually sent to database
  const [savedIds, setSavedIds] = useState<string[]>([])
  // state for toast notification
  const [toast, setToast] = useState<{ message: string, type: 'success' | 'error' } | null>(null);
  // state to hold if the user selected preference summary 
  const [isSummaryOpen, setIsSummaryOpen] = useState(false);
  // state to hold the current user info
  const [user, setUser] = useState<{id: string | number; username: string} | null>(null);

  const [isLoggedIn, setIsLoggedIn] = useState(() => {
    // check if token exists so a logged in user can stay logged in
    return localStorage.getItem('polypod_userId') !== null;
  });

  useEffect(() => {
    // grab the data from localStorage when the page loads
    const storedUser = localStorage.getItem('polypod_userId');
    const storedName = localStorage.getItem('polypod_username');

    if (storedUser) {
      setUser({
        id: storedUser,
        username: storedName || "User",
      });
    }
  }, []);

// grab available interests from backend 
  useEffect(() => {
    const loadDatabaseInterests = async () => {
      const rawData = await getAvailableInterests();
      
      if (rawData) {
        const groupedData: Record<string, { id: string }[]> = {};

        // loop through every item the backend sent us
        rawData.forEach((interest: { id: number, name: string, category: string }) => {
          
          // if category doesn't exist yet, create it
          if (!groupedData[interest.category]) {
            groupedData[interest.category] = [];
          }
          
          // push item into the correct category
          // set 'id' to the name string
          groupedData[interest.category].push({ id: interest.name });
        });

        setDataSource(groupedData);
      }
    };

    loadDatabaseInterests();
  }, []);
  

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
    localStorage.removeItem('polypod_username');
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
        <h1>Podwork</h1>
      </header>

      
      <ProfileBadge user={user} onLogout={handleLogout} />

      <CategorySlider
        dataSource={dataSource}
        selectedIds={selectedIds}
        onToggle={toggleSelection}
        activeCategory={activeCategory}
        setActiveCategory={setActiveCategory}
        activeSubCategory={activeSubCategory}
        setActiveSubCategory={setActiveSubCategory}
        onSummaryOpen={() => setIsSummaryOpen(true)}
        searchQuery={searchQuery}
        setSearchQuery={setSearchQuery}
      />
      
      {isSummaryOpen && (
        <SummaryModal
          selectedIds={selectedIds}
          onToggle={toggleSelection}
          onClose={() => setIsSummaryOpen(false)}
        />
       )}

      <ToastNotification toast={toast}/>
    </div>
    )}


export default App;