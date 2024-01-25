import React from 'react';

const QualityPercentageBar = ({ sunsetPercentage }) => {
    return (
      <div className="relative p-10 w-full">
        <div className="overflow-hidden h-1 mb-4 text-xs flex rounded bg-black bg-opacity-15">
          <div className="overflow-hidden h-1 mb-4 text-xs flex rounded bg-cyan-500" style={{ width: `${sunsetPercentage}%` }}></div>
        </div>
      </div>
    );
  };
  
  export default QualityPercentageBar;