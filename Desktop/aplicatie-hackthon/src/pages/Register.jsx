import React,{useState} from 'react'
import { Link, useNavigate } from 'react-router-dom'
import axios from 'axios';
import "./Register.css"

const Register = () => {
  const[email,setEmail]=useState('')
  const[firstName,setFirstName]=useState('')
  const[lastName,setLastName]=useState('')
  const[password,setPassword]=useState('')
  const[cpassword,setCPassword]=useState('')
  const[phoneNumber,setPhoneNumber]=useState('')
  const[role,setRole]=useState("")
  const navigate=useNavigate()
  const submit=()=>{
    console.log('submit')
    if(firstName.length>0 && email.length>0  && lastName.length>0 && password.length>0 && cpassword.length>0 && phoneNumber > 0){
    let obj={
      firstName:firstName,
      lastName:lastName,
      email:email,
      phoneNumber:phoneNumber,
      password:password,
      cpassword:cpassword,
    }

    if(cpassword!=password){
      alert('Password does not match')
    }
    axios.post('http://localhost/reactProject/insert.php',obj)
    .then(res=>{
      console.log(res.data)
      navigate("/login")
    } )
    .catch(error => {
      console.log(error.response)
    })

   setLastName("")
   setFirstName("")
   setPassword("")
   setCPassword("")
   setEmail("")
   setPhoneNumber("")
    
    console.log(obj)
   

    
    }else{
      alert('You must add all the necessary info')
    }
   
  }
  return  <div className="register">
  <div className='register-column'>
  <h1>Register</h1>
  <form method='post'>
  <div className="register-text">
  <div className="inputs">
      <p>First Name</p>
      <input placeholder="Enter first name" type='text' value={firstName} onChange={(e)=>setFirstName(e.target.value)} required/>
    </div>
    <div className="inputs">
      <p> Last Name</p>
      <input placeholder="Enter last name" type='text' value={lastName} onChange={(e)=>setLastName(e.target.value)} required/>
    </div>

    <div className="inputs">
      <p>Email</p>
      <input placeholder="Enter email" type='email' value={email} onChange={(e)=>setEmail(e.target.value)} required/>
    </div>

 
    <div className="inputs">
      <p>Phone Number</p>
      <input placeholder="Enter phone number"  value={phoneNumber}  onChange={(e)=>setPhoneNumber(e.target.value)} required/>
    </div>

    <div className="inputs">
      <p>Password</p>
      <input type='password' value={password} onChange={(e)=>setPassword(e.target.value)} placeholder="Enter your password" required/>
    </div>

    <div className="inputs">
      <p> Confirm password</p>
      <input type='password' value={cpassword} onChange={(e)=>setCPassword(e.target.value)} placeholder="Confirm your password" required/>
    </div>
  </div>
    
    <button onClick={submit} className="register-btn">Submit</button>
  

  </form>
  </div>
 
  <div className="register-go-to-login">
       <h2>Do you have an account Go to </h2>
       <Link to="/login">Login</Link>
    </div>
</div>
}

export default Register
