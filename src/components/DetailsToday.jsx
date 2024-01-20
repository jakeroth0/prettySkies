import React from "react";
//q:how would I import svgs from the public folder?
import { CloudSvg } from "../../public/cloud-svgrepo-com";
import { HumiditySvg } from "../../public/humidity-svgrepo-com";
import { TemperatureSvg } from "../../public/temperature-low-svgrepo-com";
import { UpDownSvg } from "../../public/upDown";

const DetailsToday = () => {
  const weatherData = {
    clouds: "Overcast",
    cloudHeight: "Very Low",
    temperature: "Cold",
    humidity: "None",
  };
  // q: how do I make a background transparent so that the background gradient shows through?
  //a
  return (
    <div className="flex bg-black bg-opacity-20 rounded-xl mx-5">
      <div className="flex flex-col text-white items-center  pt-2 pb-4">
        
          <p className="text-xs pl-3 pb-3 pt-1 border-b-[1px] border-white/25">
            The key to pretty skies lies in the combination of clouds, humidity,
            Sun angle, and particulates.
          </p>

        <div className="grid grid-cols-2 gap-6 pt-4 pb-2">
          <div className="flex">
            <CloudSvg />
            <span className="px-1">{weatherData.clouds}</span>
          </div>

          <div className="flex">
            <UpDownSvg />
            <span className="px-1">{weatherData.cloudHeight}</span>
          </div>

          <div className="flex">
            <TemperatureSvg />
            <span className="px-1">{weatherData.temperature}</span>
          </div>

          <div className="flex">
            <HumiditySvg />
            <span className="px-1">{weatherData.humidity}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DetailsToday;
