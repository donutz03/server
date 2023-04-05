import React from 'react'
import NavbarComp from '../components/NavbarComp'
import { useNavigate } from "react-router-dom";
import Header from '../components/Header';
const navigate = useNavigate;


const Mainpage = () => {
  const logout=()=>{
   console.log('Logout')
  }
  return <div>

    <div>
    
     <nav>
      <NavbarComp>
       <h1>Mainpage</h1>
      </NavbarComp>
        </nav> 
</div>
 
    <h2>Welcome,user</h2>
    <button onClick={logout}>Logout</button>
  </div>
}

export default Mainpage
