
@AbapCatalog.sqlViewName: 'ZCDS_MSEG1'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'MSEG View Test'
define view ZCDS_MSEG as select from matdoc as ab {
    key ab.mandt,
    key ab.mblnr, 
    key ab.mjahr,
    key ab.zeile,

    ab.rsnum,
    ab.rspos,
    @EndUserText.quickInfo: 'Connection'
    ab.budat as dddate,
    ab.kzear,
    @DefaultAggregation: #AVG
    ab.menge,
    ab.meins,
    ab.shkzg,
    ab.ebeln,
    ab.ebelp,
    ab.bwart,
    @EndUserText.label: 'Connection'
    ab.sgtxt
}  where ab.record_type = 'MDOC'
