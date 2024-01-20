import React from 'react';

const MainInfo = () => {
    const locationName = 'Richmond';
    const percentage = 75;
    const qualitySunsetPhrase = 'Great Chance';
    const startTimeOfSunset = '5:05';
    const endTimeOfSunset = '5:37';
    //can I make a p tag all caps with tailwind?
    //a:

    return (
        <div className='text-white flex flex-col items-center pt-24'>
            <h2 className=' text-5xl'>My Location</h2>
            <h3 className='uppercase'>{locationName}</h3>
            <p className='text-8xl font-extralight'>{percentage}%</p>
            <p>{qualitySunsetPhrase}</p>
            <div className='flex w-1/2 justify-evenly'>
                <p>Start:{startTimeOfSunset}</p>
                <p>End:{endTimeOfSunset}</p>
            </div>
        </div>
    );
};

export default MainInfo;
