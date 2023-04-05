import {useState} from 'react'
import axios from "axios";
import { useNavigate } from 'react-router-dom';
const FormSuggestion=()=>{
    const navigate=useNavigate()
    const[suggestion,setSuggestion]=useState("")
    const [email,setEmail]=useState("")
    const submit=(e)=>{
        e.preventDefault()
        if(suggestion.length>0){
            let obj={
                suggestion:suggestion
            }
            console.log(obj)
            axios.post("",obj)
            .then((res)=>{
                console.log(res.data.status)
            })
            .catch((error)=>{
                console.log(error)
            })
            navigate("/ideas");
        }


        console.log("click")
    }
    return(
     <form action="" method="post" className="form-suggestion">
        <div className="form-suggestion-text">
        <h3>Adauga-ti ideea care crezi ca va ajuta la crearea unui mediu mult mai eco friendly</h3>
         <p>Email</p>
         <input type="email" value={email} onChange={(e)=>setEmail(e.target.value)} required />
        <textarea type="text"  value={suggestion} onChange={(e)=>setSuggestion(e.target.value)}  required  rows="6" cols="60"/>
        </div>
        <button onClick={submit}>Submit</button>
     </form>
    )
}
export default FormSuggestion