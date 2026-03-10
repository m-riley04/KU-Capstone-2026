// src/LoginPage.tsx
import { useState } from 'react';
import { registerUser, loginUser } from './services/api';
import './styles/login.css';

interface LoginProps {
  onLogin: () => void;
}

export default function LoginPage({ onLogin }: LoginProps) {
  // the username and password entered by the user will be stored here 
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); //clears previous errors
    
    try {
        if (isSignUp){
            const payload = {
                username: username, 
                password: password,
            };

            const response = await registerUser(payload);

            if (response.ok) {
                const data = await response.json();
                localStorage.setItem('polypod_userId', data.id)
                localStorage.setItem('polypod_interests', JSON.stringify([]))
                localStorage.setItem('polypod_username', username);
                alert('Account created! You are now logged in.');
                onLogin();
            } else {
                setError('Username already taken or invalid.');
            }
        }else{
            const response = await loginUser(username, password);
            
            if (response.ok) {
                const user = await response.json();
                localStorage.setItem('polypod_userId', user.id)
                localStorage.setItem('polypod_interests', JSON.stringify(user.interests || []))
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
            style={{marginBottom: '20px'}}
          />
          
          {error && <p style={{color: 'red'}}>{error}</p>}
          
          <button type="submit" className="sign-in">
            Sign In
          </button>

        </form>

        {/* sign up button */}
        <button className='sign-up'
        onClick={() => {setIsSignUp(!isSignUp);
            setError('');
            setUsername('');
            setPassword('');
        }}
        style={{marginTop: '1rem', background: 'none', border: 'none', color: '#4f46e5', cursor: 'pointer', textDecoration: 'underline'}}>
        {isSignUp ? "Already have an account? Log in here!" : "Don't have an account? Sign up here!"}</button>
      </div>
    </div>
  );
};