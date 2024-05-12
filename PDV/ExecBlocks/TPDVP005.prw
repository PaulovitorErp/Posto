#include 'protheus.ch'
#INCLUDE "TOPCONN.CH" 

Static aLogAlcada := {} //variavel para log de alçadas

/*/{Protheus.doc} TPDVP005
Função utilizada pelo Ponto de Entrada STFinishSale

Não é recomendado a utilização desse ponto de entrada para alterar as tabelas SL1, SL2 e/ou SL4, 
pois no ponto que esta localizado o ponto de entrada a venda já subiu para a retaguarda e não ira subir novamente.

@author Maiki Perin
@since 26/09/2018
@version P12
@param PARAMIXB
@return nulo
/*/
User Function TPDVP005()

	Local nX
	Local aArea		:= GetArea()
	Local aAreaSL1  := SL1->(GetArea())
	Local aAreaSL2	:= SL2->(GetArea())
	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.) //Habilita controle de caixa por Vendedor, com exigência de senha.
	Local lMvPVBlFin := SuperGetMv("TP_PVVLFIN",,.F.) //Define se bloqueia tela do vendedor, após cada venda (controle de caixa por Vendedor)
	Local lVldDtAba := SuperGetMv("MV_VLDDTAB",,.F.) //habilita validacao data do abastecimento, dia anterior

	//Local cFil		:= PARAMIXB[1] //Filial (L1_FILIAL)
	Local cNum		:= PARAMIXB[2] //Número do Orçametno (L1_NUM)
	//Local cDoc		:= PARAMIXB[3] //Número do Cupom Fiscal (L1_SERIE)
	//Local cSerie	:= PARAMIXB[4] //Série do Cupom Fiscal (L1_DOC)

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

	///////////////////////////////////////////////////////////////////////////////////////////
	//             Funcao de integracao promoflex                                             //
	/////////////////////////////////////////////////////////////////////////////////////////
	If SuperGetMv("TP_PROFLEX",,.F.)
		If SL1->L1_XUSAPRO == 'S' .AND. !Empty(SL1->L1_XCHVPRO)
			FWMsgRun(, {|oSay| U_TPDVE016(3) }, "Conectando com PromoFlex", "Aguarde enquanto estamos validando o codigo: " + SL1->L1_XCHVPRO )
		ENDIF
	EndIf
	
	//-------------------------------------------------------------//
	// Ajusta gravação importação orçamento (problema do Situa=FR)
	// Também faz finalização da comanda, quando é conveniencia.
	//-------------------------------------------------------------//
	U_TPDVP05A()
	
	//-------------------------------------------------------------//
	// Faz impressão do comprovante de Convenios - Venda a Prazo (NP)
	//-------------------------------------------------------------//
	U_TPDVR001()

	//--------------------------------------------------------------//
	// Faço a impressão customizada da carta frete
	//--------------------------------------------------------------//
	If ExistBlock("UTPDVRCF")
		U_UTPDVRCF()
	EndIf
	
	//-------------------------------------------------------------//
	// Faz impressão do comprovante de Vale Haver
	//-------------------------------------------------------------//
	If SL1->L1_XTROCVL > 0
		U_TPDVR006(SL1->L1_XTROCVL, .F./*lCmp*/, AllTrim(SL1->L1_SERIE))
	EndIf

	//-------------------------------------------------------------//
	// Atualiza nome do cliente na tela
	//-------------------------------------------------------------//
	U_SetTbcCli("")

	//-------------------------------------------------------------//
	// Limpo mensagem da nota para a proxima venda
	//-------------------------------------------------------------//
	U_HideMsgNF()

	//-------------------------------------------------------------//
	// Atualizo parametro validacao abast. data anterior
	//-------------------------------------------------------------//
	if lVldDtAba .AND. !empty(U_GSDtVAba())
		//gravo parametro, para nao buscar mais durante o resto do dia
		GetMv("MV_DTUVABA")
		PutMvPar("MV_DTUVABA", DTOS( U_GSDtVAba() ) )
	endif

	//-------------------------------------------------------------//
	// Faz gravaçao do log de alçadas
	//-------------------------------------------------------------//
	SL1->(DbSetOrder(1)) //L1_FILIAL+L1_NUM
	SL1->(DbGoTop())
	If SL1->(DbSeek(xFilial("SL1")+cNum))
		If SuperGetMv("ES_ALCADA",.F.,.F.) .AND. !Empty(aLogAlcada)
			For nX := 1 to len(aLogAlcada)
				U_TR037LOG(aLogAlcada[nX][1], aLogAlcada[nX][2], SL1->L1_FILIAL+SL1->L1_SERIE+SL1->L1_DOC+SL1->L1_PDV, aLogAlcada[nX][3], iif(len(aLogAlcada[nX])>3,aLogAlcada[nX][4],0))
			Next nX
			U_ClLogAlc() //limpo para proxima vendas
		EndIf
	EndIf

	//-------------------------------------------------------------//
	// Tela de seleção de Cheque Troco no PDV
	//-------------------------------------------------------------//
	If FindFunction("U_TPDVE007")
		U_TPDVE007()
	EndIf

	// Limpa array do bakcup da ultima carta frete
	If FindFunction("U_TPDVA14A")
		U_TPDVA14A()
	EndIf

	//Limpo flag para integração com host superior (PE STDUPSL1)
	//Enquanto se tem o flag L1_FORCADA preenchido, aborta a subida da venda (esse campo padrão não usa no TotvsPDV)
	//A partir daqui, a venda ja pode ser integrada ao Backoffice
	RecLock("SL1", .F.)
		SL1->L1_FORCADA := " "
	SL1->(MsUnLock())

	//-------------------------------------------------------------//
	// Tratamento para vinculo compensação na venda
	//-------------------------------------------------------------//	
	if U_TPDVE04B() //se marcou sim (vincular)
		TelaComp()
	endif
	U_TPDVE04B(.F.) // Reseto opção vinculo compensação na venda

	//Seta para o vendedor logado
	If lMvPswVend
		If lMvPVBlFin
			U_TPDVE013()
		Else
			U_TpAtuVend()
		EndIf
	EndIf

	RestArea(aAreaSL1)
	RestArea(aAreaSL2)
	RestArea(aArea)

	//Tratativa para errorlog Maximum number of components per window exceeded
	oPanelMVC := STIGetPanel()
	oPanelMVC:FreeChildren()

Return

/*/{Protheus.doc}
Adiciona linhas no array para gravaçao de log da alçada

@type  Function
@author thebr
@since 26/09/2019
@version 1.0
/*/
User Function AddLogAl(cChavLog, cUserLog, cMsgLog, nVlrLid)
	Default nVlrLid := 0
	aadd(aLogAlcada,  {cChavLog, cUserLog, cMsgLog, nVlrLid} )
Return

/*/{Protheus.doc}
Limpa array de log das alçadas

@type  Function
@author thebr
@since 26/09/2019
@version 1.0
/*/
User Function ClLogAlc()
	aLogAlcada := {}
Return


/*/{Protheus.doc} TPDVP05A
Faz a verificação se teve importação de orçamento, para tratar problema
do SITUA = FR, que bagunça os SL1 na retaguarda, sobrescrevndo informaçoes.

O conceito é limpar os campo L1_NUMORIG e L2_NUMORIG para nao gravar FR nos hosts
superiores. Para manter histórico, levo o conteudo do L2_NUMORIG para L2_CODREG.
Também será feita a gravação do DOC/SERIE nos orçamentos importados na central,
para que nao apareçam mais na busca de orçamentos no PDV.

@type  Function
@author thebr
@since 26/09/2019
@version 1.0
/*/
User Function TPDVP05A()

	Local aNumOri := {}
	Local aParam, uResult
	
	If !Empty(SL1->L1_NUMORIG) //se tem importação
		
		//guardo numero origem num campo backup e no array para gravar doc/serie no orçamento central.
		SL2->(DbSetOrder(1))
		SL2->(DbSeek(SL1->L1_FILIAL + SL1->L1_NUM))
		while SL2->(!Eof()) .AND. SL2->L2_FILIAL + SL2->L2_NUM == SL1->L1_FILIAL + SL1->L1_NUM
			if !empty(SL2->L2_NUMORIG)
				if aScan(aNumOri, SL2->L2_NUMORIG) == 0
					aadd(aNumOri, SL2->L2_NUMORIG)
				endif
				RecLock("SL2",.F.)
					SL2->L2_CODREG := SL2->L2_NUMORIG
					SL2->L2_NUMORIG := ""
				SL2->(MsUnLock())
			endif
			
			SL2->(DbSkip())
		enddo

		if len(aNumOri) > 0
			//limpo origem para forçar que seja gerado novo orçamento na central
			RecLock("SL1", .F.)
				SL1->L1_NUMORIG := ""
			SL1->(MsUnLock())

			aParam := {aNumOri, SL1->L1_DOC, SL1->L1_SERIE}
			aParam := {"U_TPDVP05B",aParam}
			if FWHostPing() 
				STBRemoteExecute("_EXEC_CEN", aParam, NIL, .T., @uResult)
			endif
		endif
	    
	 EndIf
	
Return

//funçao a ser executada na central para gravaçao doc/serie orçamento
User Function TPDVP05B(aNumOri, cDoc, cSerie) 
	                                              
	Local nX
	
	//gravo doc/serie orçamento para nao aparecer mais para importar no PDV
	DbSelectArea("SL1")
	SL1->(DBSetOrder(1)) //L1_FILIAL+L1_NUM
	For nX := 1 to len(aNumOri)
		if SL1->(DbSeek(xFilial("SL1")+aNumOri[nX] ))
			if empty(SL1->L1_DOC)
				RecLock("SL1",.F.)
					SL1->L1_DOC := cDoc
					SL1->L1_SERIE := cSerie
				SL1->(MsUnLock())
			endif
		endif
	next nX

Return  


//--------------------------------------------------------------------------------------
// Inclusao de Compensação de Valores vinculada a venda
//--------------------------------------------------------------------------------------
Static Function TelaComp()

	Local bConfirm := {|| oDlgAux:end() }
	Local bCancel := {|| oDlgAux:end() }
	Local oPnlAux
	Private oDlgAux

	DEFINE MSDIALOG oDlgAux TITLE "Compensação de Valores Vinculada a Venda" FROM 000, 000  TO 650, 900 COLORS 0, 16777215 PIXEL STYLE DS_MODALFRAME

	@ 000, 000 MSPANEL oPnlAux SIZE (oDlgAux:nWidth/2), (oDlgAux:nHeight/2)-12 OF oDlgAux
	oPnlAux:SetCSS( "TPanel{border: none; background-color: #f4f4f4;}" )
	U_TPDVA005(oPnlAux, .F., bConfirm, bCancel, 3, .T.) //monta tela de compensação

	ACTIVATE MSDIALOG oDlgAux CENTERED

Return
