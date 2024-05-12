#INCLUDE 'TOPCONN.CH'

 /*/{Protheus.doc} F460NUM
PE para defninir numero da liquidação, substitindo a padrao

@type  Function
@author user
@since 20/05/2021
/*/
User Function F460NUM

    Local cLiquid		:= ""
    Local cQry

    //liquidação independente da filial e do parametro
    cQry :=" SELECT MAX(E1_NUMLIQ) AS E1_NUMLIQ FROM "+RetSqlName("SE1")+" SE1"
    cQry +=" WHERE D_E_L_E_T_ = ' ' "
    cQry +=" AND E1_NUMLIQ <> '' "

    If Select("QF460NUM") > 0
		QF460NUM->(DbCloseArea())
	EndIf
	
	cQry := ChangeQuery(cQry)
    Tcquery cQry New alias "QF460NUM"

    if Empty(QF460NUM->E1_NUMLIQ)
		cLiquid := STRZERO(1,TamSX3("E1_NUMLIQ")[1])
	else
		
		cLiquid:= SOMA1(QF460NUM->E1_NUMLIQ, TamSX3("E1_NUMLIQ")[1])
		
		//FreeUsedCode()
		While !MayIUseCode("E1_NUMLIQF460NUM"+cLiquid)
			cLiquid := Soma1(cLiquid, TamSX3("E1_NUMLIQ")[1])
		EndDo
		
	endif
	QF460NUM->(DbCloseArea())

Return cLiquid

