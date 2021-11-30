# -*- coding: utf-8 -*-
*** Settings ***
Documentation     Tilaa uuden robotin RobotSpareBin Industries Inc.
...               Tallettaa the order HTML receipt as a PDF file.
...               Tallettaa the screenshot of the ordered robot.
...               Sulauttaa the screenshot of the robot to the PDF receipt.
...               Luo ZIP archive of the receipts and the images.
...               Putsaa tarpeettomat filut ja sulkee selaimen
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.HTTP
Library           OperatingSystem
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault
Library           RPA.RobotLogListener
Variables         variables.py


*** Keywords ***
Fill the form 
    [Arguments]    ${row}
    Click Element   css:#head[name="head"]
    Select From List By Value    css:#head[name="head"]  ${row}[Head]
    Click Element    css:#id-body-${row}[Body]
    ${elem} = 	Get WebElement   class:form-control
    Input Text    ${elem}  ${row}[Legs]    True
    Input Text      address  ${row}[Address]

*** Keywords ***
Close the annoying modal
    Click Button  OK

*** Keywords ***
Preview the robot
    Click Button  preview

*** Keywords ***
Submit the order
    Click Button  order
    Klikkaa elementtia jos niikseen    class="salo-danger" #alert alert-danger
    Klikkaa elementtia jos niikseen    class="diipadaapaa"
    Wait Until Page Contains Element    id:order-completion

*** Keywords ***
Go to order another robot
    Click Button  order-another

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${kuitti}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${kuitti}    ${CURDIR}${/}output${/}robokuitti_${Order number}.pdf
    Return From Keyword  ${CURDIR}${/}output${/}robokuitti_${Order number}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${Order number}
    Screenshot    robot-preview-image   ${CURDIR}${/}output${/}robokuva_${Order number}.png
    Return From Keyword  ${CURDIR}${/}output${/}robokuva_${Order number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}  ${kuitti}
    Open PDF   ${kuitti}
    Add Watermark Image To PDF  ${screenshot}  ${kuitti}
    Close All Pdfs


*** Keywords ***
Create a ZIP file of the receipts
    [Arguments]   ${zipname} 
    Archive Folder With Zip  ${CURDIR}${/}output  ${zipname}

*** Keywords ***
Ask ZipFileName
    Add text input    ziptiedostonimi    label=Annappas tiedostonimi Zip-tiedostolle, kiitos
    ${zipname}=    Run dialog
    [Return]    ${zipname.ziptiedostonimi}

*** Keywords ***
Close the browser and remove useless files
    ${files}=    Count Files In Directory  ${CURDIR}${/}output
    ${files}=    Evaluate    ${files} / 2
    ${files}=    Convert To Integer    ${files}
    Close Browser
        FOR    ${index}    IN RANGE    ${files}
            ${index}=    Evaluate    ${index} + 1
            RPA.FileSystem.Remove File    ${CURDIR}${/}output${/}robokuva_${index}.png
            RPA.FileSystem.Remove File    ${CURDIR}${/}output${/}robokuitti_${index}.pdf
        END

*** Keywords ***
Klikkaa elementtia jos niikseen
    [Arguments]    ${locator}
    Mute Run On Failure    Click Element When Visible
    Run Keyword And Ignore Error    Click Element When Visible    ${locator}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order
    ${zipname}=  Ask ZipFileName
    ${salesurl}=  Get Secret  secreturl
    Download    ${secret}[salesurl]    overwrite=True
    ${orders}=    Read table from CSV  orders.csv   header=True
    FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Wait Until Keyword Succeeds    5x    2s   Submit the order  
         ${kuitti}=     Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${kuitti}
         Go to order another robot
    END
    Create a ZIP file of the receipts  ${zipname}
    [Teardown]    Close the browser and remove useless files
