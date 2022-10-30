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
  return <div className = "divregister">
    <h1>Register</h1>
    <form method='post'>

      <div>
        <p>First Name</p>
        <input type='text' value={firstName} onChange={(e)=>setFirstName(e.target.value)} required placeholder = "First Name"/>
      </div>
      <div>
        <p>Last Name</p>
        <input type='text' value={lastName} onChange={(e)=>setLastName(e.target.value)} required placeholder = "Last Name"/>
      </div>

      <div>
        <p>Email</p>
        <input type='email' value={email} onChange={(e)=>setEmail(e.target.value)} required placeholder = "Email"/>
      </div>

   
      <div>
        <p>Phone Number</p>
        <input type='text' value={phoneNumber} onChange={(e)=>setPhoneNumber(e.target.value)} required placeholder = "Phone Number"/>
      </div>

      <div>
        <p>Password</p>
        <input type='password' value={password} onChange={(e)=>setPassword(e.target.value)} placeholder="Password" required/>
      </div>

      <div>
        <p> Confirm password</p>
        <input type='password' value={cpassword} onChange={(e)=>setCPassword(e.target.value)} required placeholder = "Confirm Password"/>
      </div>
      <button onClick={submit}>Submit</button>
    </form>

    <div><p>Already have an account? Then <Link to = "/login">Login here</Link></p></div>
  </div>
}

export default Register
