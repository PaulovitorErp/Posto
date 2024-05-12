#include 'protheus.ch'
#include 'parmtype.ch'
#include 'poscss.ch'

/*/{Protheus.doc} TPDVP022 (STCodB2)

PE antes montagem grid tela pdv. Usado para chamar funcao de 
controle de senha por vendedor.

@author danilo
@since 09/03/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TPDVP022()

    Local oTelaPDV
    Local cCss

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return
    EndIf

    oTelaPDV := STIGetObjTela() //pego objeto da tela
    oTelaPDV:oOwner:bStart := {|| U_TPDVE013() } //bloco apos abrir a tela pdv
    
    //-------------------------------------------------------------
	// Modifico o CSS do Menu, para caber mais itens
	//-------------------------------------------------------------
    //cCss := 'TMenu{ font: bold; font-size: 13px; font-family: "Arial"; color: #FFFFFF; background-color: #284F66; border-style: solid; border-left-width: 1px; border-right-width: 1px; border-bottom-width: 1px; border-color: #07334C; width: 400px; }TMenu::item{ padding: 5px; padding-left: 25px; border-style: solid; border-bottom-width: 1px; border-color: #07334C; }TMenu::item:selected{ background-color: #07334C;}'
	cCss := POSCSS( GetClassName(oTelaPDV:oOwner:aControls[3]), CSS_BAR_MENU, 400 )
    cCss := StrTran(cCss, "padding: 10px;", "padding: 7px;")
    oTelaPDV:oOwner:aControls[3]:SetCSS(cCss)

Return
