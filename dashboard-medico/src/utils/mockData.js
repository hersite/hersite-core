// src/utils/mockData.js - Updated with historical entries

export const patientsData = [
  // 1. Rosa María Huamán (Active Demo Case - Risk: Alto)
  {
    id: "12345678", 
    initials: "RM",
    name: "Rosa María Huamán",
    dob: "21/02/2005",
    age: 21,
    weeks: 34,
    prob: 87,
    risk: "Alto",
    riskClass: "danger",
    meta: "Chota • Última lectura: 145/92",
    sys: 145,
    dia: 92,
    chartData: [
      {day: 'Lun', sys: 110, dia: 70},
      {day: 'Mar', sys: 112, dia: 72},
      {day: 'Mié', sys: 120, dia: 75},
      {day: 'Jue', sys: 130, dia: 80},
      {day: 'Hoy', sys: 145, dia: 92}
    ],
    symptoms: ["Cefalea intensa", "Alteración visual", "Hinchazón cara manos"],
    sync: "Sincronizado",
    raw_riesgo: "Riesgo_Alto"
  },
  // 2. Natividad C. Torres (Recent Case - Risk: Medio)
  {
    id: "48563214", 
    initials: "NT", 
    name: "Natividad C. Torres", 
    dob: "10/08/2001", 
    age: 24, 
    weeks: 33,
    prob: 52, 
    risk: "Medio", 
    riskClass: "warn", 
    meta: "Chota • Última lectura: 128/82",
    sys: 128, 
    dia: 82,
    chartData: [{day: 'Lun', sys: 110, dia: 70}, {day: 'Mar', sys: 115, dia: 75}, {day: 'Mié', sys: 118, dia: 78}, {day: 'Jue', sys: 122, dia: 80}, {day: 'Hoy', sys: 128, dia: 82}],
    symptoms: ["Fatiga", "Zumbido leve"],
    sync: "Hace 1h",
    raw_riesgo: "Riesgo_Medio"
  },
  // 3. Ana G. Saldaña (Recent Case - Risk: Bajo)
  {
    id: "73214589", 
    initials: "AS", 
    name: "Ana G. Saldaña", 
    dob: "05/11/1997", 
    age: 28, 
    weeks: 29,
    prob: 11, 
    risk: "Bajo", 
    riskClass: "ok", 
    meta: "Cutervo • Última lectura: 112/70",
    sys: 112, 
    dia: 70,
    chartData: [{day: 'Lun', sys: 110, dia: 70}, {day: 'Mar', sys: 112, dia: 70}, {day: 'Mié', sys: 115, dia: 72}, {day: 'Jue', sys: 110, dia: 68}, {day: 'Hoy', sys: 112, dia: 70}],
    symptoms: [],
    sync: "Hace 20m",
    raw_riesgo: "Riesgo_Bajo"
  },

  // NEW HISTORICAL ENTRIES (ANTIGUOS)
  
  // 4. Julia R. Quispe (Historical Case - Risk: Medio)
  {
    id: "23456789", 
    initials: "JQ",
    name: "Julia R. Quispe",
    dob: "15/03/1995",
    age: 31,
    weeks: 39, // Pregnancy completed historically
    prob: 65,
    risk: "Medio",
    riskClass: "warn",
    meta: "Bambamarca • Lectura Final: 135/88",
    sys: 135,
    dia: 88,
    chartData: [
      {day: 'S35', sys: 118, dia: 75},
      {day: 'S36', sys: 120, dia: 78},
      {day: 'S37', sys: 125, dia: 82},
      {day: 'S38', sys: 130, dia: 85},
      {day: 'S39', sys: 135, dia: 88} // Last check before delivery
    ],
    symptoms: ["Edema leve", "Zumbido ocasional"],
    sync: "Hace 2 años", // Historical sync time
    raw_riesgo: "Riesgo_Medio"
  },
  // 5. Carmen L. Flores (Historical Case - Risk: Bajo)
  {
    id: "34567890", 
    initials: "CF", 
    name: "Carmen L. Flores", 
    dob: "22/11/1990", 
    age: 35, 
    weeks: 40, // Pregnancy completed
    prob: 15, 
    risk: "Bajo", 
    riskClass: "ok", 
    meta: "Cutervo • Lectura Final: 115/72",
    sys: 115, 
    dia: 72,
    chartData: [
      {day: 'S36', sys: 110, dia: 70},
      {day: 'S37', sys: 112, dia: 72},
      {day: 'S38', sys: 115, dia: 75},
      {day: 'S39', sys: 112, dia: 70},
      {day: 'S40', sys: 115, dia: 72} // Completed pregnancy standard reading
    ],
    symptoms: [],
    sync: "Hace 8 meses", 
    raw_riesgo: "Riesgo_Bajo"
  },
  // 6. Ana S. Morales (Historical Case - Risk: Alto)
  {
    id: "45678901", 
    initials: "AM", 
    name: "Ana S. Morales", 
    dob: "08/09/1998", 
    age: 27, 
    weeks: 38, // Risk detected near term historically
    prob: 92, 
    risk: "Alto", 
    riskClass: "danger", 
    meta: "Chota • Lectura Final: 160/105",
    sys: 160, 
    dia: 105,
    chartData: [
      {day: 'S34', sys: 120, dia: 78},
      {day: 'S35', sys: 125, dia: 82},
      {day: 'S36', sys: 140, dia: 90}, // Early signs
      {day: 'S37', sys: 155, dia: 100}, // High priority warning
      {day: 'S38', sys: 160, dia: 105} // Historical high reading before action
    ],
    symptoms: ["Cefalea severa", "Visión borrosa", "Dolor epigástrico"],
    sync: "Hace 1 año", 
    raw_riesgo: "Riesgo_Alto"
  }
];