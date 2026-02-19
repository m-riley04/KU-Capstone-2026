// src/LoginPage.tsx
import { useState } from 'react';
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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); //clears previous errors

    if (isSignUp) {
        if (username && password){
            alert(`Account created for ${username}!`);
            onLogin();
        }else{
            setError('Please enter a username and password');
        }
    }else{
        if (username === 'admin' && password === 'password') {
            onLogin();
        } else {
            setError('Invalid credentials');
        }
    };  
    }

    //Code for when we integrate with the backend
    /* 
    const payload = {username, password};

    try {
        if (isSignUp){
            const response = await fetch(SERVER. {
                method: 'POST',
                headers: {'Content-Type': 'application/json');
                body: JSON.stringify(payload),
            });
            if (response.ok) {
                alert('Account created! You are now logged in.');
                onLogin();
            } else {
                setError('Username already taken or invalid.');
            }
        }else{
            const response = await fetch(SERVER, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload), 
            });
            if (response.ok) {
                const data = await response.json();
                console.log('Server token:', data.token); 
                onLogin(); 
            } else {
                setError('Invalid credentials (server rejected you).');
            }
        }
    }catch (err){
        setError('Server not responding');
    }
    */
    


  return (
    <div className="login-container">
      <div className="login-card">
        <h1 className='welcome-text'>
            {isSignUp ? 'Create Account': 'Welcome to Polywork'}
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
        Don't have an account? Sign up here!</button>
      </div>
    </div>
  );
}