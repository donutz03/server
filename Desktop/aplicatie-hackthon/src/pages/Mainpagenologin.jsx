import React,{useState} from 'react'
import "./Mainpagenologin.css"
import {Link } from 'react-router-dom';
import Header from '../components/Header';
import FormSuggestion from '../components/FormSuggestion';
const Mainpagenologin = () => {
 const [afla1,setAfla1]=useState(false)
 const [afla2,setAfla2]=useState(false)
 const [afla3,setAfla3]=useState(false)
 const[afla4,setAfla4]=useState(false)
  return (
    <div className = "container">
   
    <div className="container-bg">
      <Header/>
      <h1>De ce sa ti reduci amprenta de CO2  si cum sa ai un impact pozitiv asupra mediului</h1>
   
      <h3>Alternativa ta eco friendly la produsele pe care le consumi zi de zi</h3>
    </div>
   
     <div className="main-grid">
        <div  className="grid-el"  data-aos="fade-left">
            <h4>Masini electrice</h4>
            {afla1?<p></p>:(<p></p>)}
            <img src="electric-car.jpeg"/>

        </div>

        <div  data-aos="fade-right"  className="grid-el">
            <h4>Trotinete electrice</h4>
            {afla2?<p></p>:(<p></p>)}
            <img src="electric-scooter.jpeg"/>
        </div>
        <div   data-aos="fade-left"  className="grid-el">
            <h4>Puncte de reciclare haine </h4>
            {afla3?<p></p>:(<p></p>)}
            <img src="clothes.webp"/>
        </div>
    
        <div   data-aos="fade-right"  className="grid-el">
            <h4>Panouri Solare </h4>
           
           
            <img src="panouri-solare.jpeg"/>
        </div>
     

     </div>
  <FormSuggestion/>
   
        </div>
    
  )
}

export default Mainpagenologin