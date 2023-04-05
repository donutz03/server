
import {Link} from "react-router-dom"
const Header=()=>{
    return(
        <div className="header">
           <Link to="login">Login</Link>
           <Link to="/register">Register</Link>
           <Link to="/ideas">Ideas Page</Link>
        </div>
    )
}
export default Header