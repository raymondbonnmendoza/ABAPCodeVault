@AbapCatalog.sqlViewName: 'ZTEST_1'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'TEST'
/*define view Ztest as select from sflight as a {
    key case carrid
     when 'AA' then 'American Airlines'
     when 'AZ' then 'American Zealots'
     end as Airline,
    key connid,
    max(price) as MaxPrice,
    min(price) as MinPrice,
    avg(price) as AvgPrice
    } group by carrid, connid 
      having carrid = 'AA' */
   
   
/*define view Ztest as select from sflight as a {
    key carrid,
    key connid,
    ( seatsocc_b + seatsocc_f ) * price as payment
    } */
    
/*
  define view Ztest as select from sflight as a {
    key carrid,
    key connid,
    CONCAT(carrid, currency)as carridcurrency
    } */
    
/*
 define view Ztest
  as select from spfli
    inner join   scarr on
      spfli.carrid = scarr.carrid
  {
    scarr.carrname  as carrier,
    spfli.connid    as flight,
    spfli.cityfrom  as departure,
    spfli.cityto    as arrival
  } */
  
/*
define view Ztest
  as select from spfli
  association [1] to scarr as _scarr on
    spfli.carrid = _scarr.carrid
  {
    carrid as carrid,
    _scarr[inner].carrname as carrier,
    spfli.connid           as flight,
    spfli.cityfrom         as departure,
    spfli.cityto           as arrival,
    _scarr
  } */
   
 
 define view Ztest with parameters param:abap.char( 2 ) as select from sflight as a  {
    key case carrid
     when 'AA' then 'American Airlines'
     when 'AZ' then 'American Zealots'
     end as Airline,
    key connid,
    max(price) as MaxPrice,
    min(price) as MinPrice,
    avg(price) as AvgPrice
    } group by carrid, connid 
      having carrid = $parameters.param
