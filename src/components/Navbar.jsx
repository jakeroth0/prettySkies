import React from 'react';


function Navbar() {
    return (

        <nav className='absolute bottom-0 w-screen'>
            <ul className='bg-blue-500 flex text-white'>
                <li><a href="/">Home</a></li>
                <li><a href="/about">About</a></li>
                <li><a href="/contact">Contact</a></li>
            </ul>
        </nav>
    );
}

export default Navbar;
