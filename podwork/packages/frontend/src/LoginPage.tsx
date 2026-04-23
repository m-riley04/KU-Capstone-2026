/* src/LoginPage.tsx
File to handle the login/signup 
Key functionality 
- user can log in with an existing account
- user can create an account if they don't have one already
- makes call to the api.tsx file 
*/
import { useMemo, useState } from 'react';
import { registerUser, loginUser } from './services/api';
import './styles/login.css';
import { useLocation, useNavigate } from 'react-router-dom';

interface LoginProps {
  onLogin: () => void;
  mode: 'login' | 'signup';
}

export default function LoginPage({ onLogin, mode }: LoginProps) {
  // the username and password entered by the user will be stored here 
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const isSignUp = mode === 'signup';
  const navigate = useNavigate();
  const location = useLocation();

  const deviceId = useMemo(() => {
    const params = new URLSearchParams(location.search);
    return (
      params.get('userid')?.trim() ||
      ''
    );
  }, [location.search]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); //clears previous errors
    console.log('mode', mode);
    try {
        if (isSignUp){
            const payload = {
                username: username, 
                password: password,
            };

          const response = await registerUser(payload, deviceId || undefined);

            if (response.ok) {
                const data = await response.json();
                localStorage.setItem('polypod_userId', data.id)
                localStorage.setItem('polypod_interests', JSON.stringify([]))
                localStorage.setItem('polypod_username', username);
                if (data.deviceid) {
                    const deviceids = data.deviceid.split(',').map((id: string) => id.trim());
                    console.log('Received device IDs from server:', deviceids);
                    localStorage.setItem('polypod_deviceIds', JSON.stringify(deviceids));
                } else {
                    localStorage.setItem('polypod_deviceIds', JSON.stringify([]));
                }
                alert('Account created! You are now logged in.');
                onLogin();
            } else {
                setError('Username already taken or invalid.');
            }
        }else{
            console.log('attempting login with', username, password);
            const response = await loginUser(username, password, deviceId || undefined);
            
            if (response.ok) {
                console.log('login successful');
                const user = await response.json();
                localStorage.setItem('polypod_userId', user.id)
                localStorage.setItem('polypod_interests', JSON.stringify(user.interests || []))
                if (user.deviceid) {
                    const deviceids = user.deviceid.split(',').map((id: string) => id.trim());
                    console.log('Received device IDs from server:', deviceids);
                    localStorage.setItem('polypod_deviceIds', JSON.stringify(deviceids));
                } else {
                    localStorage.setItem('polypod_deviceIds', JSON.stringify([]));
                }
                localStorage.setItem('polypod_username', user.username || username);
                onLogin(); 
            } else {
                setError('Invalid credentials (server rejected you).');
            }
        }
    }catch (err){
        setError('Server not responding');
    }
}
    
  return (
    <div className="login-container">
      <div className="login-card">
        <h1 className='welcome-text'>
            {isSignUp ? 'Create Account': 'Welcome to Podwork'}
        </h1>
        
        {/* form to enter username and password*/}
        <form onSubmit={handleSubmit}>
          <input 
            type="text" 
            placeholder="Username" 
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            className="login-input"
            style={{marginBottom: '30px'}}
          />
          <input 
            type="password" 
            placeholder="Password" 
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="login-input"
            style={{marginBottom: '30px'}}
          />
          
          {error && <p style={{color: 'red'}}>{error}</p>}
          
          <button type="submit" className="sign-in">
            { isSignUp ? 'Sign Up' : 'Sign In' }
          </button>

        </form>

        {/* sign up button */}
        <button className='sign-up'
        onClick={() => {
            setError('');
            setUsername('');
            setPassword('');
            navigate({
              pathname: isSignUp ? '/login' : '/create-account',
              search: location.search,
            });
        }}
        style={{marginTop: '1rem', background: 'none', border: 'none', color: '#4f46e5', cursor: 'pointer', textDecoration: 'underline'}}>
        {isSignUp ? "Already have an account? Log in here!" : "Don't have an account? Sign up here!"}</button>
      </div>
    </div>
  );
};