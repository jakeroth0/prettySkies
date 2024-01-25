
import './App.css'
import Navbar from './components/Navbar'
import MainInfo from './components/MainInfo'
import DetailsToday from './components/detailsToday'
import QualityPercentageBar from './components/QualityPercentageBar'
import DayForecast from './components/DayForecast'

function App() {

  return (
    <>  
      <Navbar />
      <body className='min-h-screen w-screen bg-gradient-to-b from-[#8AB3CE] via-[#A14D70] to-[#F16D58]'>
      <MainInfo />
      <DetailsToday />
      <DayForecast sunsetPercentage={90}/>
      <QualityPercentageBar sunsetPercentage={20}/>
      </body>
    </>
  )
}

export default App