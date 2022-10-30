// Import the functions you need from the SDKs you need
import { initializeApp } from 'firebase/app'
import { getAnalytics } from 'firebase/analytics'
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: 'AIzaSyDAfVOFFM7wMQRQjeAE9ggqtu2I6vZyG4k',
  authDomain: 'hackathon-app-9283d.firebaseapp.com',
  projectId: 'hackathon-app-9283d',
  storageBucket: 'hackathon-app-9283d.appspot.com',
  messagingSenderId: '885102100536',
  appId: '1:885102100536:web:5cf5ce89249bd71cf4a6cd',
  measurementId: 'G-LC6KF5121R',
}

// Initialize Firebase
const app = initializeApp(firebaseConfig)
const analytics = getAnalytics(app)
