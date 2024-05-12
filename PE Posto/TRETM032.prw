#include 'protheus.ch'
#include 'parmtype.ch'
#include "topconn.ch"

/*/{Protheus.doc} TRETM032
Ponto de Entrada Cadastro Requisições
@author thebr
@since 29/04/2019
@version 1.0
@return xRet
@type function
/*/
user function TRETM032()

	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ''
	Local cIdPonto   := ''
	Local cIdModel   := ''
	Local cClasse    := ''
	Local lIsGrid    := .F.
	Local nLinha     := 0
	Local nQtdLinhas := 0
	Local lSrvPDV

	If aParam <> NIL

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := IIf( oObj<> NIL, oObj:GetId(), aParam[3] ) //cIdModel   := aParam[3]
		cClasse    := IIf( oObj<> NIL, oObj:ClassName(), '' )

		lIsGrid    := ( Len( aParam ) > 3 ) .and. cClasse == 'FWFORMGRID'
		nOperation := oObj:GetOperation()

		If lIsGrid
			nQtdLinhas := oObj:GetQtdLine()
			nLinha     := oObj:nLine
		EndIf

		If cIdPonto == 'MODELVLDACTIVE'

			xRet := VldOperation(oObj)

		ElseIf cIdPonto == 'FORMPOS'

			xRet := VldFields(oObj)

		ElseIf cIdPonto == 'MODELPOS'

			xRet := ExcTitulos()

		ElseIf cIdPonto == 'MODELCOMMITNTTS'

			if nOperation == 3 .OR. nOperation == 4
				GrvTotais(oObj)

				If !isBlind()
					lSrvPDV  := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV
					If !lSrvPDV //se nao for base PDV
						if U56->U56_TIPO == "1" //pre paga
							U_TRETA32A()
						endif
						If MsgYesNo("Deseja imprimir a requisição cadastrada?","Imprimir?")
							U_TRETR010(.F.,U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO),U57->U57_PARCEL)
						EndIf
					EndIf
				EndIf
			endif
			
		EndIf

	EndIf

Return xRet

//-------------------------------------------------------
// Gravações especificas após comit
//-------------------------------------------------------
Static Function GrvTotais(oObj)

	Local aArea     := GetArea()
	Local aAreaU56	:= U56->(GetArea())
	Local aAreaU57	:= U57->(GetArea())
	Local nTOT := 0, nTOTC := 0, nTOTS := 0, nQTD := 0

	dbselectarea("U57")
	U57->(dbsetorder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
	If U57->(dbseek(U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO)))
		while U57->(!EOF()) .and. U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO) == U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO)
			nTOT  += U57->U57_VALOR
			If U57->U57_TUSO == "C"
				nTOTC += U57->U57_VALOR
			Else
				nTOTS += U57->U57_VALOR
			EndIf
			nQTD  += 1
			U57->(dbskip())
		EndDo
	EndIf

	dbSelectarea( "U56" )
	RecLock( "U56", .F. )
	If ( U56->U56_TIPO == "2" ) .and. ( U56->U56_STATUS <> "L" )
		U56->U56_STATUS := "L"
	elseIf ( U56->U56_TIPO == "1" ) .and. ( U56->U56_STATUS <> "L" )
		U56->U56_STATUS := "N"
	EndIf
	U56->U56_NPARC  := nQTD
	U56->U56_TOTAL  := nTOT
	U56->U56_TOTCON := nTOTC //total consumo
	U56->U56_TOTSAQ := nTOTS //total troco/saque
	U56->( MsUnlock() )

	RestArea( aAreaU56 )
	RestArea( aAreaU57 )
	RestArea( aArea )

Return

//-------------------------------------------------
// Valda o acesso a operação
//-------------------------------------------------
Static Function VldOperation(oModel)

	Local lRet 		 := .T.
	Local nOperation := oModel:GetOperation()
	Local aArea		:= GetArea()
	Local aAreaU57 	:= U57->(GetArea())

	If (nOperation == 4) .and. (U56->U56_STATUS == "L" .AND. U56->U56_TIPO == "1")
		lRet := .F.
		Help( ,, 'Help - MODELVLDACTIVE',, 'Não é permitido a alteração, pois a requisição Pré-Paga já esta liberada!', 1, 0 )
	ElseIf ( nOperation == 4 .or. nOperation == 5) .and. U56->U56_TIPO == "2"
		
	EndIf

	RestArea(aAreaU57)
	RestArea(aArea)

Return lRet

//----------------------------------------------------------
// Exclui os titulos gerados
//----------------------------------------------------------
Static Function ExcTitulos()

	Local aArea      := GetArea()
	Local aAreaSE1   := SE1->(GetArea())
	Local aAreaSE5   := SE5->(GetArea())
	Local aAreaU57   := U57->(GetArea())
	Local lRet       := .T.
	Local oModel     := FWModelActive()
	Local nOperation := oModel:GetOperation()
	Local aFin040    := {}
	Local cPulaLinha := chr(13)+chr(10)

	Local lSrvPDV  := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV

	If !lSrvPDV .AND. nOperation == 5

		BeginTran() //controle de transação

		DbSelectArea("U57")
		U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
		If U57->(DbSeek(U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO)))
			lRet := .T.
			While lRet .and. U57->(!EOF()) .and. U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO) == U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO)

				//faz o estorno de todos os títulos
				cQry := "select SE1.R_E_C_N_O_ AS SE1RECNO" + cPulaLinha
				cQry += " from " + RetSqlName("SE1") + " SE1" + cPulaLinha
				cQry += " where SE1.D_E_L_E_T_ <> '*'" + cPulaLinha
				cQry += " and SE1.E1_XCODBAR = '" + AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) + "'" + cPulaLinha

				If Select("QRYSE1") > 0
					QRYSE1->(DbCloseArea())
				EndIf

				cQry := ChangeQuery(cQry)
				TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

				//QRYSE1->(dbEval({|| nCount++}))
				QRYSE1->(DbGoTop())

				If lRet .and. QRYSE1->(!Eof())
					While lRet .and. QRYSE1->(!EOF())

						SE1->(DbGoTo(QRYSE1->SE1RECNO))
						If SE1->(!Eof()) .and. AllTrim(SE1->E1_XCODBAR) == AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL)

							//PABLO: se é um RA e esta baixado com motivo "TRF - TRANSF. DE RA ENTRE COLIG", exclui a baixa
							If SE1->E1_TIPO = 'RA ' .and. !Empty(SE1->E1_BAIXA) .and. SE1->E1_SALDO <= 0
								cChaveSe1:= SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)
								SE5->(dbSetOrder(7))
								If SE5->(dbSeek(xFilial("SE5")+cChaveSE1))
									While !Eof() .and. SE5->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA) == cChaveSE1
										If SE5->E5_MOTBX == "TRF" .and. SE5->E5_RECPAG == "P"
											If DtMovFin(SE5->E5_DTDISPO,.F.)
												dBkpDt := dDataBase
												dDataBase := SE5->E5_DTDISPO
												lRet := U_TR028CBX() //Cancela baixa do título posicionado
												dDataBase := dBkpDt
											Else
												MsgStop("Não são permitidas movimentações financeiras com datas menores que a data limite de movimentações no Financeiro."+;
														"Verificar parâmetro MV_DATAFIN.","DTMOVFIN")
												lRet := .F.
											EndIf
											Exit //sai do While
										EndIf
										SE5->(DbSkip())
									EndDo
								EndIf
							EndIf

							aFin040 := {}
							AADD( aFin040, {"E1_FILIAL"  , SE1->E1_FILIAL , Nil})
							AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO, Nil})
							AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM,     Nil})
							AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA, Nil})
							AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO,    Nil})
							If Alltrim(SE1->E1_TIPO) == "RA"
								AADD( aFin040, {"CBCOAUTO" , SE1->E1_PORTADO  ,Nil})
								AADD( aFin040, {"CAGEAUTO" , SE1->E1_AGEDEP ,Nil})
								AADD( aFin040, {"CCTAAUTO" , SE1->E1_CONTA  ,Nil})
							EndIf

							lMsErroAuto := .F.
							lMsHelpAuto := .T.

							RecLock("SE1",.F.)
							SE1->E1_ORIGEM := ""
							SE1->(MsUnLock())

							dBkpDt 		:= dDataBase
							cBkpFi		:= cFilAnt
							dDataBase 	:= SE1->E1_EMISSAO
							cFilAnt		:= SE1->E1_FILIAL

							//DANILO: Tratamento para exclusão do RA
							If Alltrim(SE1->E1_TIPO) == "RA"
								SE5->(dbSetOrder(7))
								If SE5->(dbSeek(xFilial("SE5")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
									If !empty(SE5->E5_DTDISPO)
										dDataBase := SE5->E5_DTDISPO
									EndIf
								EndIf
								RestArea(aAreaSE5)
							EndIf

							If DtMovFin(,.F.)
								//Invocando rotina automática para exclusão do título;
								MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 5)
							Else
								MsgStop("Não são permitidas movimentações financeiras com datas menores que a data limite de movimentações no Financeiro."+;
										"Verificar parâmetro MV_DATAFIN.","DTMOVFIN")
								lRet := .F.
								Exit
							EndIf

							dDataBase 	:= dBkpDt
							cFilAnt		:= cBkpFi

							If lMsErroAuto
								MostraErro()
								lRet := .F.
								Exit
							ElseIf !(SE1->(Deleted()))
								MsgStop("Não foi possível excluir o título abaixo:"+chr(13)+chr(10)+chr(13)+chr(10)+;
								"Filial:  "+SE1->E1_FILIAL+chr(13)+chr(10)+;
								"Prefixo: "+SE1->E1_PREFIXO+chr(13)+chr(10)+;
								"Número:  "+SE1->E1_NUM+chr(13)+chr(10)+;
								"Parcela: "+SE1->E1_PARCELA+chr(13)+chr(10)+;
								"Tipo:    "+SE1->E1_TIPO+chr(13)+chr(10)+;
								"Favor verificar o status financeiro do título.","Atenção")
								lRet := .F.
								Exit
							EndIf
						EndIf

						QRYSE1->(DbSkip())
					EndDo
				EndIf

				If Select("QRYSE1") > 0
					QRYSE1->(DbCloseArea())
				EndIf

				U57->(DbSkip())
			EndDo

		EndIf

		If !lRet
			DisarmTransaction()
		EndIf

		EndTran()

	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaU57)
	RestArea(aArea)

Return lRet

//---------------------------------------------------
// valida campos obrigatórios, dependendo do tipo
//---------------------------------------------------
Static Function VldFields(oObj)

	Local oModel      := FWModelActive()
	Local oModelU56   := oModel:GetModel( 'U56MASTER' )
	Local oModelU57   := oModel:GetModel( 'U57DETAIL' )
	Local aSaveLines  := FWSaveRows()
	Local lRet 		  := .T.
	Local lRqSaq      := .F.
	Local nX
	Local lReqCliPad := SuperGetMv("MV_XRQCPAD",,.F.) //permite requsição para cliente padrao? 
	Local cCliPad 	  := SuperGetMv("MV_CLIPAD",,"")
	Local cLojPad 	  := SuperGetMv("MV_LOJAPAD",,"")

	If !lReqCliPad .AND. oModelU56:GetValue('U56_CODCLI')+oModelU56:GetValue('U56_LOJA') == cCliPad+cLojPad
		Help(,,'Help',,"Não é permitida a inclusão de requisições para Cliente Padrão.",1,0)
		lRet := .F.
	EndIf

	If lRet .AND. oModelU56:GetValue('U56_TIPO') == "1" //Pré-Paga

		If (empty(oModelU56:GetValue('U56_BANCO')) .or. empty(oModelU56:GetValue('U56_AGENCI')) .or. empty(oModelU56:GetValue('U56_NUMCON'))) //pre paga
			Help(,,'Help',,"Requisição do tipo 'Pré-Paga' requer o preenchimento completo das informações bancárias." + CRLF + CRLF +;
			"Checar o preenchimentos dos dados de 'Banco', 'Agencia' e 'Conta'.",1,0)
			lRet := .F.
		ElseIf U56->(FieldPos("U56_HIST")) > 0 .and. empty(oModelU56:GetValue('U56_HIST'))
			Help(,,'Help',,"Requisição do tipo 'Pré-Paga' requer o preenchimento completo das informações bancárias." + CRLF + CRLF +;
			"Checar o preenchimento do campo 'Numero de Documento'.",1,0)
			lRet := .F.
		EndIf

		If lRet
			For nX := 1 To oModelU57:Length()
				// posiciono na linha atual
				oModelU57:Goline(nX)
				If oModelU57:GetValue('U57_VALOR') <= 0 .and. !(oModelU57:IsDeleted() )
					Help(,,'Help',,"Requisição do tipo 'Pré-Paga' requer o preenchimento do valor das parcelas.",1,0)
					lRet := .F.
					Exit //sai do For
				EndIf
			Next nX
		EndIf

	ElseIf lRet .AND. oModelU56:GetValue('U56_TIPO') == "2" //Pós-Paga

		For nX := 1 To oModelU57:Length()
			oModelU57:Goline(nX)// posiciono na linha atual
			If oModelU57:GetValue('U57_TUSO') == "S"
				lRqSaq := .T.
				Exit //sai do For
			EndIf
		Next nX

		If  Empty(oModelU56:GetValue('U56_CONDSA')) .and. lRqSaq
			Help(,,'Help',,"Requisição do tipo 'Pós-Paga de Saque' requer o preenchimento completo das informações de pagamento." + CRLF + CRLF +;
			"Checar o preenchimentos dos dados de 'Condição de Pagamento de Saque' (U56_CONDSA).",1,0)
			lRet := .F.
		EndIf

	EndIf

	FWRestRows( aSaveLines )

Return lRet
