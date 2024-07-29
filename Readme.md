
# Task Board API

This project provides a Task Board API, allowing users to manage their tasks. The API is built using TypeScript, Node.js, Express, and MongoDB.

## Features

- User authentication and management
- Task board creation and management
- Task management within task boards
- CRUD operations for tasks and task boards

## Requirements

- Node.js (v14 or later)
- MongoDB (local or cloud instance)

## Setup Instructions

### 1. Clone the repository

```sh
git clone https://github.com/hritik189/workflo-backend.git
cd workflo-backend
```

### 2. Install dependencies

```sh
npm install
```

### 3. Set up environment variables

Create a `.env` file in the root directory of the project and add the following variables:

```env
PORT=8000
ORIGIN=http://localhost:3000
MONGODB_URI=mongodb://localhost:27017/
JWT_SECRET=your_jwt_secret
```

### 4. Connect to MongoDB

Make sure your MongoDB server is running. If you are using a cloud instance, update the `MONGODB_URI` in the `.env` file accordingly.

### 5. Seed the database

To seed the database with initial data, run the following script:

```sh
npm run seed
```

### 6. Start the server

```sh
npm run dev
```

The server will start on the port specified in the `.env` file (default is 8000).

## API Endpoints

### User Endpoints

- **POST** `/api/auth/signup` - Register a new user
- **POST** `/api/auth/login` - Login a user
- **GET** `/api/auth/validate` - validate a user
- **POST** `/api/auth/logout` - LogOut a user
- 
### Task Board Endpoints

- **POST** `/api/task-board` - Create a new task board
- **GET** `/api/task-board/:userId` - Get a task board by user ID
- **PUT** `/api/task-board/:userId` - Update a task board by user ID

#### Delete Task

- **Method:** DELETE
- **URL:** `http://localhost:8000/api/task-board/{userId}/task/{taskId}`
- **Params:**
  - `userId` - The ID of the user
  - `taskId` - The ID of the task to be deleted


## Postman Setup

### Create Task Board

- **Method:** POST
- **URL:** `http://localhost:8000/api/task-board`
- **Body:**
  ```json
  {
    "userId": "user_id_here",
    "tasks": [
      {
        "title": "Task 1",
        "description": "Task 1 description",
        "status": "To-Do",
        "priority": "Medium",
        "deadline": "2024-07-29"
      },
      {
        "title": "Task 2",
        "description": "Task 2 description",
        "status": "In Progress",
        "priority": "Urgent",
        "deadline": "2024-07-30"
      }
    ]
  }
  ```

## License

This project is licensed under the MIT License.
