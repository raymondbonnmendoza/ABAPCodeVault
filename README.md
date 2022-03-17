# ABAPCodeVault
Reusable code, module specific sample programs, useful FMs, classes and info for ABAP developers

## Simple OOP Report using MVC and SALV
This report is an Object-Oriented approach for ABAP using the MVC design pattern. It also implements the SALV object for ALV display

## Create Message Log using SLG1
This messaging Log is an Object-Oriented approach for ABAP.  The result can be viewed in tcode SLG1.

## Email Sending thru Distribution List
This report is a mix of OOP and procedural programming with the aim of showing how to send email to the distribution list.  You need to setup the distribution List in SO23, and place all the email address whom you want to serve as receiver.  

## Zebra Printer Label
This report shows how Zebra Printer Language (ZPL) commands are used in ABAP programs. 

## Shared Memory Object
Code and Classes needed to use the Shared Memory Object function equivalent to the obsolete IMPORT FROM MEMORY/EXPORT TO MEMORY ABAP Commands

## Inbound and Outbound ABAP Proxy Logic
Outbound - Sample code is trigerred during Payment Medium Event 41 to send a file outbound using ABAP Proxy.

Inbound - The inbound sample code demonstrates a payload with attachment using an inbound ABAP Proxy and how to get the attachment and store in an App Server directory(AL11)

## Sales Order OData Service Useful Methods
iwbepif_mgw_appl_srv_runtime~create_stream: Post an attachment to a Sales Order from a POST request to the Odata service
iwbepif_mgw_appl_srv_runtime~delete_stream: Delete an attachment from a Sales Order
iwbepif_mgw_appl_srv_runtime~get_stream: Retrieve an attachment from a Sales Order from a GET request to the Odata service
orderitems_update_entity: Update Sales Order items (VBAP) with BAPI_SALESORDER_CHANGE using Schedules(bapischdl), Conditions(bapicond) and Z-Extensions(bape_vbap, bapiparex)
salesorders_update_entity: Update Sales Order header (VBAK) with BAPI_SALESORDER_CHANGE using Z-Extensions(bape_vbak, bapiparex)
