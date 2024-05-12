#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#include 'parmtype.ch'
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TPDVP014 (StClsFCash)
Ponto de entrada no final do fechamento de caixa

@author thebr
@since 20/12/2018
@version 1.0
@return lRet
@type function
/*/
User Function TPDVP014()

	Local aArea := GetArea()
	//Local aParam := aClone(ParamIxb)
	Local aItensCh := {}
	Local lMvXGERENT := SuperGetMv("MV_XGERENT",,.F.)
	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

	//LjGrvLog("TPDVP014", "(StClsFCash) Antes chamada consulta de cheques.")

	//considero que ja está posicionado no SLW
	Reclock("SLW", .F.)
	SLW->LW_ORIGEM  := "POS"
	SLW->LW_CONFERE := "2"
	SLW->(MsUnlock())

	// Pablo Cavalcante
	// Data: 15/04/2019
	// Processa a rotino do monitor que "recupera" vendas autorizadas
	//If FindFunction("U_xMonitor") --> comentado pois não existe EXECAUTO LOJA701
	//	U_xMonitor(cEmpAnt, cFilAnt, SLW->LW_DTABERT)
	//EndIf

	//faz impressao do relatório de caixa
	If lMvPswVend
		U_TRA028RI()
	Else
		U_TRA028RL()
	EndIf

	RestArea(aArea)

	//limpo SAY do nome cliente
	U_SetTbcCli("")
	U_HideMsgNF()
	U_TPDVE04B(.F.) // Reseto opção vinculo compensação na venda

	//Prepara para consultar cheques trocos que serão transferidos para usuario PDV.
	aItensCh := U_TPDVP16A()
	If Len(aItensCh)>0
		U_TRETR013(3,aItensCh) //impressao dos cheques transfereridos
		If lChTrOp
			U_TPDVP14A() //limpo os dados de operador e PDV das folhas desse caixa
		EndIf
	EndIf

	//tratamento para filtrar caixas combo abertura caixa
	If lMvXGERENT
		U_TPDVE014(1)
	EndIf

Return

/*/{Protheus.doc} TPDVP14A
Quando o usuário de caixa finalizar o turno e realizar o fechamento do caixa, 
será removido automaticamente o vínculo das folhas de cheque do PDV e do Operador, 
ficando as folhas de cheque aptas a vincular em outro operador em outro momento.

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
User Function TPDVP14A()

	Local cCaixa := xNumCaixa()
	Local cQry := ""

	#IFDEF TOP

		cQry := "SELECT UF2.R_E_C_N_O_ RECUF2 "
		cQry += " FROM " + RetSqlName("UF2") + " UF2 "
		cQry += " WHERE UF2.D_E_L_E_T_ = ' ' "
		cQry += " AND UF2_FILIAL = '" + xFilial("UF2") + "' "
		cQry += " AND UF2_CODCX = '" + PadR(cCaixa,TamSx3("UF2_CODCX")[1]) + "' "
		cQry += " AND UF2_DOC = '"+Space(TamSx3("UF2_DOC")[1])+"' "
		cQry += " AND UF2_SERIE = '"+Space(TamSx3("UF2_SERIE")[1])+"' "
		cQry += " AND UF2_STATUS <> '2' AND UF2_STATUS <> '3' "
		cQry += " ORDER BY UF2_FILIAL, UF2_BANCO, UF2_AGENCI, UF2_CONTA, UF2_NUM"

		If Select("QAUX") > 0
			QAUX->(dbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QAUX"

		If QAUX->(!Eof())
			While QAUX->(!Eof())

				UF2->(DbGoTo(QAUX->RECUF2))

				RecLock("UF2",.F.)
				UF2->UF2_CODCX 	:= ""
				UF2->UF2_PDV 	:= ""
				if UF2->(FieldPos("UF2_DTREM"))
					UF2->UF2_DTREM 	:= STOD("")
				endif
				UF2->(MsUnLock())

				U_UREPLICA("UF2", 1, UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM), "A")

				QAUX->(DbSkip())

			EndDo
		EndIf

		QAUX->(dbCloseArea())

	#ENDIF

Return
