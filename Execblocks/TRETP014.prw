#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} TRETP014 (LJ720VLFIN)
Ponto de Entrada que permite efetuar validações no momento da finalização do
processo de troca/devolução de mercadorias (Troca/Devolução).

@author thebr
@since 14/01/2019
@version 1.0
@return lRet

@type function
/*/
User function TRETP014()

	Local nX := nZ := 0
	Local aArea := GetArea()
	Local lRet := .T.

	//Local lCompCR	:= ParamIxb[1] //Lógico				Indica se irá compensar o valor da NCC gerada com o título da nota fiscal original.
	Local nFormaDev := ParamIxb[2] //Array of Record	Define a forma de devolução ao cliente, sendo: 1- Dinheiro/2- NCC
	Local nTpProc 	:= ParamIxb[3] //Array of Record	Tipo do processo, sendo: 1- Troca/2- Devolução
	//Local nNfOrig 	:= ParamIxb[4] //Array of Record	Opção selecionada, sendo: 1-Com NF de origem/2-Sem NF de origem
	//Local lFormul 	:= ParamIxb[5] //Array of Record	Indica se utilizará formulário próprio para a Nota Fiscal de Entrada.
	Local aRecSD2 	:= ParamIxb[6] //Array of Record	Array que contém o Recno() do produto da tabela SD2 (Itens de Venda da NF), com ele é possível obter informações da nota.

	Local aDocs	:= {}, aAutoriz := {}
	Local lVldDev := SuperGetMV("MV_XVLDDEV",,.F.) //Habilita validação de nota autorizada na devolução (default .F.)
	Local lConferencia := IsInCallStack("U_TRETA028")

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return lRet
	EndIf

	If nTpProc == 2  .and. ; 	//Processo: 2-Devolução
		nFormaDev == 2  		//Forma de Devolução: 2-NCC

		//preenche a lista de notas: aDocs
		SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		For nX:=1 to Len(aRecSD2)
			SD2->(DbGoTo(aRecSD2[nX][2]))
			If aScan(aDocs, {|x| AllTrim(x[1]+x[2]+x[3])==AllTrim(SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE)}) <= 0
				aadd(aDocs, {SD2->D2_FILIAL,SD2->D2_DOC,SD2->D2_SERIE,SD2->D2_CLIENTE,SD2->D2_LOJA})
			EndIf
		Next nX

		//valida se as notas selecionadas para devolução pertencem ao caixa logado
		If lRet
			SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
			For nX:=1 to Len(aDocs)
				
				If lConferencia
					If !SL1->(DbSeek(xFilial("SL1")+aDocs[nX][3]+aDocs[nX][2]+AllTrim(SLW->LW_PDV))) .or. ;
						!(DtoS(SL1->L1_EMISNF)+SL1->L1_HORA >= DtoS(SLW->LW_DTABERT)+SLW->LW_HRABERT ;
							.AND. DtoS(SL1->L1_EMISNF)+SL1->L1_HORA <= DtoS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA ;
							.AND. SL1->L1_FILIAL = SLW->LW_FILIAL ;
							.AND. SL1->L1_OPERADO = SLW->LW_OPERADO ;
							.AND. SL1->L1_NUMMOV = SLW->LW_NUMMOV ;
							.AND. SL1->L1_PDV = AllTrim(SLW->LW_PDV) ;
							.AND. SL1->L1_ESTACAO = SLW->LW_ESTACAO)

						MsgAlert("A nota N. "+aDocs[nX][2]+"/"+aDocs[nX][3]+" não pertence a esse caixa.","Atenção")
						lRet := .F.
						Exit
					EndIf
				EndIf

				If lVldDev
					//-- Validação de autorização de nota
					SF2->(DbSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
					SF2->(DbSeek(aDocs[nX][1]+aDocs[nX][2]+aDocs[nX][3]+aDocs[nX][4]+aDocs[nX][5]))
					
					lRet := .F.
					aAutoriz := U_STMVLSEF(.T./*consulta no TSS Local*/, {{SF2->F2_SERIE,SF2->F2_DOC,.F.,Iif(SF2->F2_ESPECIE="SPED","55","65")}} )
					If ValType(aAutoriz) == "A"
						for nZ := 1 to len(aAutoriz)
							//-- Sped esta Autorizada na SEFAZ??
							If Len(aAutoriz[nZ]) >= 05 .AND. SubStr(aAutoriz[nZ][05],1,3) == "100"
								lRet := .T.
								Exit
							Elseif Len(aAutoriz[nZ]) >= 09 .AND. SubStr(aAutoriz[nZ][09],1,3) == "001" //autorizado tbm
								lRet := .T.
								Exit
							EndIf
						next nZ
					EndIf
					if !lRet
						MsgAlert("A nota N. "+aDocs[nX][2]+"/"+aDocs[nX][3]+" está com status diferente de '100 - Autorizado o uso da NF-e'.","Atenção")
					endif
				EndIf

			Next nX
		EndIf

		//valido se tem cheque troco ou vale haver
		if lRet .AND. lConferencia
			For nX:=1 to Len(aDocs)
				UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
				if UF2->(DbSeek(aDocs[nX][1]+aDocs[nX][2]+aDocs[nX][3]+AllTrim(SLW->LW_PDV)))
					MsgAlert("A nota N. "+aDocs[nX][2]+"/"+aDocs[nX][3]+" tem cheque troco amarrado. Não permitido!","Atenção")
					lRet := .F.
					Exit
				endif
				if lRet 
					SE1->(DbSetOrder(1))
					if SE1->(DbSeek(aDocs[nX][1]+aDocs[nX][3]+aDocs[nX][2]+SubStr("VLH",1,TamSX3("E1_PARCELA")[1])+"NCC"))
						MsgAlert("A nota N. "+aDocs[nX][2]+"/"+aDocs[nX][3]+" tem vale haver amarrado. Não permitido!","Atenção")
						lRet := .F.
						Exit
					endif
				endif
			next nX
		endif

		//valida as formas de pagamento
		If lRet
			If lConferencia
				For nX:=1 to Len(aDocs)
					If VerifFPg(aDocs[nX][2],aDocs[nX][3])
						MsgInfo("Para prosseguir será necessário trocar todas as formas de pagamentos da nota N. "+aDocs[nX][2]+"/"+aDocs[nX][3]+" para dinheiro (R$).","Atenção")

						SL1->(DbSeek(xFilial("SL1")+aDocs[nX][3]+aDocs[nX][2]+AllTrim(SLW->LW_PDV)))
						U_TR028TFO(1) //chama troca forma de pagamento

						If VerifFPg(aDocs[nX][2],aDocs[nX][3])
							MsgAlert("Para prosseguir é necessário trocar todas as formas de pagamentos da nota N. "+aDocs[nX][2]+"/"+aDocs[nX][3]+" para dinheiro (R$).","Atenção")
							lRet := .F.
							Exit
						EndIf

					EndIf
				Next nX
			EndIf
		EndIf

	EndIf

	RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
// Verifica se o cupom tem alguma forma de pagamento diferente de R$
//-------------------------------------------------------------------
Static Function VerifFPg(_cDoc,_cSerie)

	Local lRet	:= .F.
	Local cQry	:= ""

	cQry := "SELECT E1_EMISSAO, E1_TIPO, E1_VALOR, E1_VLRREAL, E1_VENCREA, R_E_C_N_O_ RECSE1"
	cQry += " FROM "+RetSqlName("SE1")+" SE1"
	cQry += " WHERE SE1.D_E_L_E_T_ <> '*'"
	cQry += " AND E1_FILIAL = '"+xFilial("SE1")+"'"
	cQry += " AND E1_NUM = '"+Alltrim(_cDoc)+"'"
	cQry += " AND E1_PREFIXO = '"+_cSerie+"'"
	cQry += " AND E1_PARCELA <> '"+SubStr("VLH",1,TamSX3("E1_PARCELA")[1])+"'"

	cQry += " AND E1_TIPO <> 'R$ '" //se existe alguma forma de pagamento diferente de dinheiro

	// trata os titulos transferidos de outras filiais
	cQry += " AND NOT EXISTS ("
	cQry += " SELECT SE6.E6_NUM "
	cQry += " FROM " + RetSqlName("SE6") + " SE6"
	cQry += " WHERE SE6.E6_FILIAL = SE1.E1_FILIAL"
	cQry += " AND SE6.E6_PREFIXO = SE1.E1_PREFIXO"
	cQry += " AND SE6.E6_NUM = SE1.E1_NUM"
	cQry += " AND SE6.E6_PARCELA = SE1.E1_PARCELA"
	cQry += " AND SE6.E6_TIPO = SE1.E1_TIPO"
	cQry += " AND SE6.E6_CLIENTE = SE1.E1_CLIENTE"
	cQry += " AND SE6.E6_LOJA = SE1.E1_LOJA"
	cQry += " AND SE6.D_E_L_E_T_ <> '*')"

	cQry += " ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO"

	If Select("TSE1") > 0
		TSE1->(DbCloseArea())
	EndIf

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "TSE1"

	If TSE1->(!Eof())
		lRet := .T.
	EndIf

	TSE1->(DbCloseArea())

Return lRet
