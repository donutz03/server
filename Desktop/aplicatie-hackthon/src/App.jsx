import {BrowserRouter,Routes,Route} from "react-router-dom"
import Login from "./pages/Login"
import Register from "./pages/Register"
import Mainpage from "./pages/Mainpage"
import Mainpagenologin from "./pages/Mainpagenologin"
import {AuthContext} from "./context/AuthContext";
import {useContext}from "react"
import Footer from "./components/Footer"
function App() {
 // const { state } = useContext(AuthContext);
  return (
    <div className="app">
       <BrowserRouter>
         <Routes>
      
         <Route path='/login' element={<Login/>}/>
           <Route path='/' element={<Mainpagenologin/>}/>
          <Route path='/register' element={<Register/>}/>
          <Route path='/mainpage'element = {<Mainpage/>}/>
         </Routes>
         <Footer/>
       </BrowserRouter>
    </div>
  )
}

export default App
