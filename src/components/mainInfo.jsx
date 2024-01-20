import React from 'react';

const MainInfo = () => {
    const locationName = 'Richmond';
    const percentage = 75;
    const qualitySunsetPhrase = 'Great Chance';
    const startTimeOfSunset = '5:05';
    const endTimeOfSunset = '5:37';

    return (
        <div className='text-white flex flex-col items-center pt-24 pb-12'>
            <h2 className=' text-4xl drop-shadow-lg'>My Location</h2>
            <h3 className='uppercase text-xs pb-2'>{locationName}</h3>
            <p className='text-8xl font-extralight drop-shadow-4xl pb-2'>{percentage}%</p>
            <p className='drop-shadow-lg text-xl'>{qualitySunsetPhrase}</p>
            <div className='flex w-1/2 justify-between drop-shadow-lg text-xl'>
                <p>Start: {startTimeOfSunset}</p>
                <p>End: {endTimeOfSunset}</p>
            </div>
        </div>
    );
};

export default MainInfo;
