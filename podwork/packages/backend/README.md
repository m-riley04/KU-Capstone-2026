# podwork 

This is the webapp that connects to the polypod and allows users to change their preferences about which events they would like the polypod to notify them on 

## Backend Start Up
To start up your backend run 

``` 
npm i 
npm run build:backend
npm run start:backend
```

## server
This directory is for storing all code related to the backend server.

## Routes and What is returned 

The service layer handles:
- Password hashing (`bcrypt`)
- Authentication
- Interest association
- Data validation before database calls

---

# Base Assumptions

All routes return **JSON**.

Common error responses:

| Status | Meaning |
|--------|---------|
| 400 | Bad request (missing/invalid input) |
| 404 | Resource not found |
| 500 | Internal server error |

---

# Get User (Authenticate)
GET /users/:username

## Required
- `req.params.username`
- Header: `x-password`

## Success Response    
Status: 200 
{
  "id": 1,
  "username": "hannah",
  "email": "hannah@email.com",
  "password": "$2b$10$hashedValue...",
  "interests": [
    { "id": 2, "name": "NBA" },
    { "id": 5, "name": "Technology" }
  ]
}

# Create User  
## Assumes that users will never be created with interests
POST /users
## Required
{
  "username": "hannah",
  "email": "hannah@email.com",
  "password": "password123"
}
## Success Response
status 201 
{
  "id": 1,
  "username": "hannah",
  "email": "hannah@email.com",
  "password": "$2b$10$hashedValue..."
}

# Update User  
PUT /users/:userId
## Required
req.params.userId
Body must include updated_user
### Example Body
{
  "updated_user": {
    "username": "newName",
    "email": "new@email.com",
    "password": "newPassword",
    "interests": [
      {
        "name": "Aave (AAVE)"
      },
      {
        "name": "Bitcoin Cash (BCH)"
      }
    ]
  }
}
## Success Response
status 200 
{
    "id": 1,
    "email": "Breanna.Spencer@hotmail.com",
    "password": "$2b$10$32Y5gDfdCcj/iHX1RmTr4eB5WPjbskXSjoSmgxXJFdjnK8diQ7TJu",
    "username": "hannah_smith",
    "created_at": "2026-02-24 05:20:46",
    "updated_at": "2026-02-24 05:25:15",
    "interests": [
        {
            "id": 76,
            "name": "Aave (AAVE)",
            "category": "Crypto"
        },
        {
            "id": 81,
            "name": "Bitcoin Cash (BCH)",
            "category": "Crypto"
        }
    ]
}
# Delete User   
DELETE /users/:userId
## Required
req.params.userId
## Success Response
status 200 
{ "message": "User deleted successfully" }


## Quick Overview 
This is a typescript backend, that connects to a mySQL DB 

## File Structure 
There are a lot of folders here is a break down going top to bottom 

### server.ts 
this starts the typescript server, runs migrations, seeds the interests database if it needs to be

### Routes 
does all the pure routing 

### Controller 
converts routes to service call 

### Services
This does all the buisness logic -- this will probably get more complicated as we bring in 3rd party APIs 

### Repositories 
All the SQL queries live here

### DB
This runs the DB connection for both the test, and dev db (eventually the prod db), this holds the migrations, the code that runs the migrations and seeds the interest database


