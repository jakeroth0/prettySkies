
import './App.css'
import Navbar from './components/Navbar'
import MainInfo from './components/MainInfo'
import DetailsToday from './components/detailsToday'

function App() {

  return (
    <>  
      <Navbar />
      <body className='min-h-screen w-screen bg-gradient-to-b from-[#8AB3CE] via-[#A14D70] to-[#F16D58]'>
      <MainInfo />
      <DetailsToday />
      </body>
    </>
  )
}

export default App