import React from "react";
import QualityPercentageBar from "./QualityPercentageBar";

const DayForecast = ({ day, weatherIcon, sunsetPercentage, percentage }) => {
  const currentDate = new Date();
  const isToday = currentDate.getDay();
  const weekday = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][currentDate.getDay()];

  //this is a container with the day of the week, a weather icon, a quality percentage bar, and a percentage
  return (
    <div className="flex w-screen items-center">
      <span className="text-white ml-4">{isToday ? "Today" : weekday}</span>
      <img src="https://img.icons8.com/ios/50/cloud--v1.png" alt="Cloud Icon" width="50" height="50" className="ml-10" />
      <QualityPercentageBar sunsetPercentage={sunsetPercentage} />
      <span className="text-white mr-4">{sunsetPercentage}%</span>
    </div>
  );
};

export default DayForecast;
