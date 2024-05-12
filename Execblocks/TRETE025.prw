#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'

/*/{Protheus.doc} TRETE025
Reprocessar NCC de Compensação
-> NCC com saldo maior de zero

@author Totvs GO
@since 02/05/2019
@version 1.0
@return ${return}, ${return_description}
@param _cXEmp, , descricao
@param _cXFil, , descricao
@type function
/*/
User Function TRETE025(_cXEmp, _cXFil)

Local cPulaLinha := chr(13)+chr(10)
Local aArea := GetArea()
Local cLog  := ""
Local cQry  := ""

Default _cXEmp 	:= cEmpAnt
Default _cXFil 	:= cFilAnt

	//Conout(">> INICIO TRETE025 - REPROCESSA NCC DE COMPENSAÇÃO")

		cLog += "<TRETE025> - Reprocessar NCC de compensação"
		cLog += ">> DATA: "+ DToC(Date()) +" - HORA: " + Time()
		cLog += cPulaLinha

		cLog += cPulaLinha
		cLog += " >> SELECAO DOS REGISTROS..." + cPulaLinha

		cQry := "SELECT SE1.R_E_C_N_O_ AS SE1RECNO, SE1.* FROM " + RetSqlName("SE1") + " SE1" + cPulaLinha
		cQry += " WHERE SE1.D_E_L_E_T_ <> '*'" + cPulaLinha
		cQry += " AND SE1.E1_TIPO = 'NCC'" + cPulaLinha
		cQry += " AND SE1.E1_PREFIXO = 'CMP'" + cPulaLinha
		cQry += " AND SE1.E1_SALDO > 0" + cPulaLinha
		cQry += " ORDER BY E1_FILIAL, E1_NUM" + cPulaLinha

		cLog += cPulaLinha
		cLog += " >> QUERY: "
		cLog += cPulaLinha
		cLog += cPulaLinha
		cLog += cQry
		cLog += cPulaLinha
		cLog += cPulaLinha

		If Select("QRYSE1") > 0
			QRYSE1->(DbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

		If QRYSE1->(!Eof())
			While QRYSE1->(!Eof())
				UC0->(DbsetOrder(1))
				If UC0->(DbSeek(QRYSE1->E1_FILIAL+QRYSE1->E1_NUM))

					SE1->(DbGoTo(QRYSE1->SE1RECNO))
					cFilAnt := QRYSE1->E1_FILIAL

					cErro := ""
					RecLock("UC0", .F.)
						UC0->UC0_GERFIN := "R"
					UC0->(MsUnlock())
					U_TRETE024(QRYSE1->E1_NUM,@cErro)
					If !Empty(cErro)
						cLog += " >> Erro: " + cErro
						cLog += cPulaLinha

						SE1->(DbGoTo(QRYSE1->SE1RECNO))
						aFin040     := {}
						lMsErroAuto := .F.
						lMsHelpAuto := .F.

						AADD( aFin040, {"E1_FILIAL"  , SE1->E1_FILIAL  	,Nil})
						AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO 	,Nil})
						AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM	   	,Nil})
						AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA	,Nil})
						AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO  	,Nil})

						MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 5) //rotina automática para exclusao de titulo

						If lMsErroAuto
							if !IsBlind()
								MostraErro()
							else
								cErroExec := MostraErro("\temp")
						 		//Conout(" ============ ERRO =============")
								//Conout(cErroExec)
								cErroExec := ""
							endif
						Else
							cErro := ""
							RecLock("UC0", .F.)
								UC0->UC0_GERFIN := "R"
							UC0->(MsUnlock())
							U_TRETE024(QRYSE1->E1_NUM,@cErro)
							If !Empty(cErro)
								cLog += " >> Erro: " + cErro
								cLog += cPulaLinha
							EndIf
						EndIf

					EndIf

				EndIf
				QRYSE1->(DbSkip())
			EndDo
		EndIf

		QRYSE1->(DbCloseArea())
		//conout(cLog)

	//Conout(">> FIM TRETE025 - REPROCESSA NCC DE COMPENSAÇÃO")
	RestArea(aArea)

Return
