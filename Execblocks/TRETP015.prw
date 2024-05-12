#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} TRETP015 (LJ720FIM)
Esse ponto de entrada é executado ao final da rotina de troca/devolução, chamada na
venda assistida, na qual é passado o Array com os dados para uma eventual atualização.

@author thebr
@since 14/01/2019
@version 1.0
@return Nil

	- baixar a ncc
		BxNcc(nRec,cBanco,cAgencia,cNumCon)
	- gerar sangria no caixa (banco CDV)
		ULOJA076 AjusSng(nValor,cBanco,.T.) -> inclui
		ULOJA076 AjusSng(nValor,cBanco,.F.,nValor) -> exclui
		TRETA028 -> U_TRA028SG
		ULOJA170 -> U_ULJ170SG
	- transmitir a NF de devolução
		RptStatus -> transmissão com SPEDNFETRF
	- abrir monitor de notas
		SpedNFe6Mnt(cSerie,cNotaIni,cNotaFim, lCte, lMDFe, cModel)
	- gera pedido de venda
		LocxGrvPed
	- prepara doc de saida
		Ma410PvNfs

@type function
/*/
user function TRETP015()

	Local aArea := GetArea()
	Local cMV_XBCOCDV := AllTrim(SuperGetMV("MV_XBCOCDV",,""))	// Banco de Devoluções: banco + agencia + conta (A6_COD+A6_AGENCIA+A6_NUMCON)
	Local aDocDev := ParamIxb[1] //Array of Record - Armazena a série, número e cliente+loja da NF de devolução e o tipo de operação (1=troca ou 2=devolução)
	Local cParcela := PadR(SuperGetMV("MV_1DUP"), TamSX3("E1_PARCELA")[1])
	//Local nRec := 0
	//Local cBanco := ""
	//Local cAgencia := ""
	//Local cNumCon := ""
	Local lConferencia := ""
	Local nRecNoSC5 := 0
	Local lOK := .T.
	Local lTSefDev := SuperGetMV("MV_XTSFDEV",,.T.)//transmite automatico nota devolução para sefaz?

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

	lConferencia := IsInCallStack("U_TRETA028")

	SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
	SA6->(DbSeek(xFilial("SA6")+cMV_XBCOCDV))

	LjGrvLog( "TRETP015", "aDocDev", aDocDev)
	
	If len(aDocDev) >= 5 .AND. aDocDev[5] = 2 //1=troca ou 2=devolução

		//posiciona no documento de entrada (nf de devolucao)
		SF1->(DbSetOrder(1)) //F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
		If SF1->(DbSeek(xFilial("SF1")+aDocDev[2]+aDocDev[1]+aDocDev[3]+aDocDev[4]+"D"))

			//-- ajusta o flag para não considerar a devolução na geração do LMC
			If SF1->(FieldPos("F1_XLMC")) > 0
				RecLock("SF1", .F.)
					SF1->F1_XLMC := 'N'
				SF1->(MsUnlock())
			EndIf

			If lConferencia
				//posiciona na NCC gerada
				SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				If SE1->(DbSeek(xFilial("SE1")+SF1->F1_SERIE+SF1->F1_DOC+cParcela+"NCC"))

					//baixar a ncc
					If BxNcc(SE1->(RecNo()), SA6->A6_COD, SA6->A6_AGENCIA, SA6->A6_NUMCON)

						//gerar sangria no caixa (banco CDV)
						//Função que faz inclusao dos movimentos (saida/entrada) na SE5
						U_TRA028SG(2, SF1->F1_VALBRUT, SA6->A6_COD+SA6->A6_AGENCIA+SA6->A6_NUMCON, SLW->LW_OPERADO, SLW->LW_DTABERT, SLW->LW_HRABERT, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, "TRETA028")

					Else
						MsgInfo("Não foi possível baixar a NCC, fazer a sangria e transmitir a nota. Por favor fazer o processo manualmente.","Baixa NCC")
					EndIf
				Else
					MsgInfo("Não foi possível baixar a NCC, fazer a sangria e transmitir a nota. Por favor fazer o processo manualmente.","Contas a receber")
				EndIf
			EndIf

			//transmite a NF de devolução
			if lTSefDev
				MsgRun("Aguarde, transmitindo a nota "+AllTrim(SF1->F1_DOC)+"/"+AllTrim(SF1->F1_SERIE)+"...",,{|| TransNF()})

				//abre o monitor de notas para verificar status de autorização da NF de devolução
				SpedNFe6Mnt(SF1->F1_SERIE,SF1->F1_DOC,SF1->F1_DOC, .T.)
			endif

			If lConferencia
				//atualiza grid principal da tela de conferencia de caixa
				U_TR028AVG( "", 4, .T.) //Atualizo a tela principal da conferencia
			EndIf

		Else
			MsgInfo("Não foi localizada a nota de entrada: "+aDocDev[2]+"/"+aDocDev[1],"Documento de entrada")
			lOK := .F.
		EndIf
	Else
		lOK := .F.
		If lConferencia
			MsgInfo("Não foi possível baixar a NCC, fazer a sangria e transmitir a nota. Por favor fazer o processo manualmente.")
		Else
			MsgInfo("Não foi possível transmitir a nota. Por favor fazer o processo manualmente.")
		EndIf
	EndIf

	If !lConferencia .AND. lOK
		If MsgYesNo( "Deseja incluir Pedido de Venda com os dados da nota de devolução?", "Pedido de Venda" )
			
			Processa({|| nRecNoSC5 := LocxGrvPed()},'Gerando informacao de pedidos...') //'Gerando informacao de pedidos...'

			If nRecNoSC5 > 0

				//"Prep.Doc.Saída"
				dbSelectArea("SC5")
				dbSetOrder(1)
				SC5->( DbGoTo( nRecNoSC5 ) )
				If SC5->( !Eof() )
					If LibCred() //Rotina para gerar liberacoes manuais de cred. e estoque

						SC5->( Ma410PvNfs(Alias(), Recno()) ) //prepara doc de saida

						If MsgYesNo("Deseja fazer agora a compensação do título gerado?","Compensação de títulos")
							UCompensaNCC(aDocDev) //faz compensação da NCC da NF devolução
						EndIf

					EndIf
				EndIf

			EndIf
			
		EndIf
	EndIf

	RestArea(aArea)

Return

/*
UCompensaNCC
Chama tela de compensacao de titulos financeiros para uma NCC
Obs.: Considera que o arquivo de cabecalho da NF SF2 (NF avulsa) ja esta posicionado no registro correto
*/

Static Function UCompensaNCC(aDocDev)

Local aArea := GetArea()
Local aAreaSF1 := SF1->(GetArea())
Local aAreaSD1 := SD1->(GetArea())
Local aAreaSF2 := SF2->(GetArea())
Local aAreaSE1 := SE1->(GetArea())

Local cCompNc	:= GetNewPar("MV_COMPNC","3") //Indica qdo comp. a NCC-NDE 1-Sempre compensa,2-Nunca,3-Pergunta
Local aPergs	:=	{} //Array com o conteudo das perguntas feitas na tela de NF
Local lRet  := .F. //Retorno da funcao
Local cFNameAtual := ""

Private aRotina := {} //MenuDef()
Private cCadastro := "Compensação de Títulos a Receber"  //"Compensa‡„o de Titulos a Receber"
Private cLote			// Utilizado para Contabilizacao
Private VALOR 	:= 0 	// Utilizada para Contabilizacao
Private VALORMF := 0 	// Utilizada para Contabilizacao
Private VALOR7 		:= 0 		//Utilizada para Contabilizacao
Private VALOR8 		:= 0 		//Utilizada para Contabilizacao
Private REGVALOR	:= 0	    //Utilizada para Contabilizacao
Private lOracle	:= "ORACLE"$Upper(TCGetDB())

Private nTamTit := TamSX3("E1_PREFIXO")[1]+TamSX3("E1_NUM")[1]+TamSX3("E1_PARCELA")[1]
Private nTamTip := TamSX3("E1_TIPO")[1]
Private nTamLoj := TamSX3("E1_LOJA")[1]
Private aTxMoedas	:=	{}
Private cCodDiario	:= ""

Private nIrfFina06 := 0 //ERRO: variable does not exist NIRFFINA06 on FA330TIT(FINA330.PRX)

	//³Chama o grupo de Perguntas e acerta o array de perguntas³
	//O tipo da variavel aPergunta estah sendo modificado para que a funcao Pergunte nao 
	//restaure a pergunta anterior
	If Type("aPergunta")=="A"
		aPergunta  := NIL        
	EndIf

	LoteCont( "FIN" )
	SetKey (VK_F12,{|a,b| AcessaPerg("FIN330",.T.)})

	Pergunte("FIN330",.F.)
	// MV_PAR01 : Considera Loja  Sim/Nao
	// MV_PAR02 : Considera Cliente     Original/Outros
	// MV_PAR03 : Do Cliente
	// MV_PAR04 : Ate Cliente
	// MV_PAR05 : Compensa Titulos Transferidos S/[N]
	// MV_PAR06 : Calcula Comissao sobre valores de NCC
	// MV_PAR07 : Mostra Lancto Contabil
	// MV_PAR08 : Considera abatimentos para compensar
	// MV_PAR09 : Contabiliza On-Line
	// MV_PAR10 : Considera Filiais abaixo
	// MV_PAR11 : Filial De
	// MV_PAR12 : Filial Ate
	// MV_PAR13 : Calcula Comissao sobre valores de RA
	// MV_PAR14 : Reutiliza taxas informadas

	//AEval(aPergunta,{|x,y| AAdd(aPergs,&("MV_PAR"+StrZero(y,2))==1)})
	MV_PAR01 := 2 //Considera Cliente? -> Não
	MV_PAR02 := 2 //Considera Loja? -> Não
	MV_PAR03 := SPACE(TamSX3("A1_COD")[1])
	MV_PAR04 := Replicate("Z",TamSX3("A1_COD")[1])

	//posiciona na NF devolução
	SF1->(DbSetOrder(1)) //F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	SF1->(DbSeek(xFilial("SF1")+aDocDev[2]+aDocDev[1]+aDocDev[3]+aDocDev[4]+"D"))

	//posiciona no título de crédito da NF devolução
	SE1->(DBSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	SE1->(DbSeek(xFilial("SE1")+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC+'1  '+'NCC'))
	//SE1->(DbSeek('0101'+'000007'+'1 '+'1  '+'000351796'+'1  '+'NCC'))

	If SE1->(!Eof()) // se posicionou no NCC da NF devolução
		cFNameAtual := FunName()
		SetFunName("FINA330")
		Fa330Comp(/*cAliasI*/,,1,oMainWnd,/*cX5Lote*/,/*"COMPENSANCC"*/)
		SetFunName(cFNameAtual)
	Else
		lRet := .F.
	EndIf

RestArea(aAreaSF1)
RestArea(aAreaSD1)
RestArea(aAreaSF2)
RestArea(aAreaSE1)
RestArea(aArea)

Return lRet

//---------------------------------------------------------------------
// Baixa a NCC da devolução
//---------------------------------------------------------------------
Static Function BxNcc(nRec,cBanco,cAgencia,cNumCon)

	Local lRet 		:= .T.
	Local _aBaixa 	:= {}
	Local _cGetDt	:= dDataBase
	Local cBkpFunNam := FunName()
	Local cMotBxDv := SuperGetMv("TP_MOTBXDV",,"CRE") //define motivo de baixa para vale serviço

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	SE1->(DbGoto(nRec))

	_aBaixa := {;
			{"E1_PREFIXO"   ,SE1->E1_PREFIXO				,Nil},;
			{"E1_NUM"       ,SE1->E1_NUM					,Nil},;
			{"E1_PARCELA"   ,SE1->E1_PARCELA				,Nil},;
			{"E1_TIPO"      ,SE1->E1_TIPO					,Nil},;
			{"E1_CLIENTE" 	,SE1->E1_CLIENTE 				,Nil},;
			{"E1_LOJA" 		,SE1->E1_LOJA 					,Nil},;
			{"AUTMOTBX"     ,cMotBxDv /*"NOR"*/				,Nil},;
			{"AUTBANCO"     ,cBanco 						,Nil},;
			{"AUTAGENCIA"   ,cAgencia			 			,Nil},;
			{"AUTCONTA"     ,cNumCon						,Nil},;
			{"AUTDTBAIXA"   ,_cGetDt						,Nil},;
			{"AUTDTCREDITO" ,_cGetDt 						,Nil},;
			{"AUTHIST"      ,"BAIXA REF DEVOLUCAO NO CX"	,Nil},;
			{"AUTJUROS"     ,0                  		    ,Nil,.T.},;
			{"AUTVALREC"    ,SE1->E1_VALOR					,Nil}}

	SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)					
	MSExecAuto({|x,y| Fina070(x,y)}, _aBaixa, 3) //Baixa contas a receber
	SetFunName(cBkpFunNam)

	If lMsErroAuto
		MostraErro()
		lRet := .F.
	EndIf

Return lRet

//---------------------------------------------------------------------
// Transmite NFe de devolução (considera que esta posicionado na SF1)
//---------------------------------------------------------------------
Static Function TransNF()

	Local cRetorno		:= ""	//mensagem de retorno
	Local cIDEnt		:= ""
	Local cAmbiente		:= ""
	Local cModalidade	:= ""
	Local cVersao		:= ""
	Local lRetorno		:= .F.
	Local lEnd			:= .F.
	Local aArea			:= GetArea()
	Local aSF1aArea		:= SF1->( GetArea() )
	Local lAux 			:= .T.

	Private bFiltraBrw := {||}	//usado por compatibilidade por causa do fonte SPEDNFE.PRX

	MV_PAR01 := SF1->F1_SERIE
	MV_PAR02 := SF1->F1_DOC
	MV_PAR03 := SF1->F1_DOC

	//---------------------------
	// Obtem o codigo da entidade
	//---------------------------
	cIdEnt := RetIdEnti()
	
	If !Empty(cIDEnt)

		//------------------------------------
		// Obtem os parametros do servidor TSS
		//------------------------------------
		//carregamos o array estatico com os parametros do TSS
		//If StaticCall(LOJNFCE, LjCfgTSS, "55")[1]
		lAux := &("StaticCall(LOJNFCE, LjCfgTSS, '55')[1]")
		If lAux
			//cAmbiente	:= StaticCall(LOJNFCE, LjCfgTSS, "55", "AMB")[2]
			//cModalidade := StaticCall(LOJNFCE, LjCfgTSS, "55", "MOD")[2]
			//cVersao		:= StaticCall(LOJNFCE, LjCfgTSS, "55", "VER")[2]
			cAmbiente	:= &("StaticCall(LOJNFCE, LjCfgTSS, '55', 'AMB')[2]")
			cModalidade := &("StaticCall(LOJNFCE, LjCfgTSS, '55', 'MOD')[2]")
			cVersao		:= &("StaticCall(LOJNFCE, LjCfgTSS, '55', 'VER')[2]")

			//------------------------------
			// Realiza a transmissão da NF-e
			//------------------------------
			//conout( "[IDENT: " + cIDEnt+"] - Iniciando transmissao NF-e de entrada! - " + Time() )

			cRetorno := SpedNFeTrf(	"SF1"	, SF1->F1_SERIE, SF1->F1_DOC , SF1->F1_DOC ,;
									cIDEnt	, cAmbiente	   , cModalidade , cVersao	   ,;
									@lEnd	, .F.		   , .F. )

			lRetorno := .T.

			//conout( "[IDENT: " + cIDEnt+"] - Transmissao da NF-e de entrada finalizada! - " + Time() )
			/*
			3 ULTIMOS PARAMETROS:
				lEnd - parametro não utilizado no SPEDNFeTrf
				lCte
				lAuto
			*/
		Else
			cRetorno += "Não foi possível obter o valor dos parâmetros do TSS." + CRLF
			cRetorno += "Por favor, realize a transmissão através do Módulo FATURAMENTO." + CRLF
		EndIf
	Else
		cRetorno += "Não foi possível obter o Código da Entidade (IDENT) do servidor TSS." + CRLF
		cRetorno += "Por favor, realize a transmissão através do Módulo FATURAMENTO." + CRLF
	EndIf

	//restaura as areas
	RestArea(aSF1aArea)
	RestArea(aArea)

Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ LocxGrvPed   ³ Autor ³ Bruno Sobieski	³ Data ³ 21.06.02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Criar um novo pedido em base a uma devolucao               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                      			                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ 								                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ LOCXNF                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function LocxGrvPed()
Local aHeadC6 	:= {}
Local nB :=	0, nUsado := 0, nACols := 0, nCntFor := 0
Local nRecNoSC5 := 0
Local cCadAux	:=	""
Local aColsC6 := {}
Local aItOrigem := {}
Local nX
Local cMenFis := ""
Local cCondPag := SuperGetMV("MV_XCNDPDE",,"001") //Condição de Pagamento do Pedido de Venda da NF Avulsa
Local aSX3SC6
Local cFNameAtual := FunName()

SetFunName("MATA410")

aSX3SC6 := FWSX3Util():GetAllFields( "SC6" , .T./*lVirtual*/ )
If !empty(aSX3SC6)
	For nX := 1 to len(aSX3SC6)
		If ((X3Uso(GetSx3Cache(aSX3SC6[nX],"X3_USADO")) .And. ;
			!( Trim(aSX3SC6[nX]) == "C6_NUM" ) .And.;
			Trim(aSX3SC6[nX]) # "C6_QTDEMP"  .And.;
			Trim(aSX3SC6[nX]) # "C6_QTDENT") .And.;
			cNivel >= GetSx3Cache(aSX3SC6[nX],"X3_NIVEL"))

			aadd(aHeadC6, U_UAHEADER(aSX3SC6[nX]) )
		endif
	next nX
endif 

ProcRegua(2)

SD1->(DbSetOrder(1))
SD1->(DbSeek(xFilial()+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
While !SD1->(EOF()) .And. SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA==;
									xFilial('SD1')+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA
	If SF1->F1_TIPODOC == SD1->D1_TIPODOC      
		IncProc()
		//+------------------------------------------------------+
		//¦ Preenche aCols                                       ¦
		//+------------------------------------------------------+
		nB++
		nUsado := Len(aHeadC6)
		aadd(aColsC6,Array(nUsado+1))
		nAcols := Len(aColsC6)
		aColsC6[nAcols,nUsado+1] := .F.
		For nCntFor := 1 To nUsado
			Do Case
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_ITEM"    )
					aColsC6[nAcols,nCntFor] :=   STRZero(nB,TamSx3("C6_ITEM")[1])
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_QTDVEN"  )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_QUANT
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_QTDLIB"  )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_QUANT
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_PRCVEN"  )
					aColsC6[nAcols,nCntFor] :=   A410Arred(((SD1->D1_TOTAL-SD1->D1_VALDESC)/SD1->D1_QUANT),"C6_PRCVEN")
				//Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_PRUNIT"  )
				//	aColsC6[nAcols,nCntFor] :=   A410Arred(SD1->D1_VUNIT,"C6_PRUNIT")
				//Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_DESCONT" )
				//	aColsC6[nAcols,nCntFor] :=   A410Arred(((SD1->D1_VALDESC / A410Arred(SD1->D1_QUANT * SD1->D1_VUNIT,"C6_PRCVEN"))*100) ,"C6_DESCONT") //SD1->D1_DESC
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_VALDESC" )
					aColsC6[nAcols,nCntFor] :=   A410Arred(SD1->D1_VALDESC,"C6_VALDESC") 
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_OP"      )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_OP
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_PRODUTO" )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_COD
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_UM"      )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_UM
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_SEGUM"   )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_SEGUM
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_UNSVEN"  )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_QTSEGUM
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_DESCRI"  )
					aColsC6[nAcols,nCntFor] :=   Posicione('SB1',1,xFilial('SB1')+SD1->D1_COD, 'B1_DESC')
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_CC"      )
					aColsC6[nAcols,nCntFor] :=   Posicione('SB1',1,xfilial('SB1')+SD1->D1_COD, 'B1_CC')
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_CONTA"   )
					aColsC6[nAcols,nCntFor] :=   Posicione('SB1',1,xfilial('SB1')+SD1->D1_COD, 'B1_CONTA')
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_ITEMCTA" )
					aColsC6[nAcols,nCntFor] :=   Posicione('SB1',1,xFilial('SB1')+SD1->D1_COD, 'B1_ITEMCC')
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_CLVL"    )
					aColsC6[nAcols,nCntFor] :=   Posicione('SB1',1,xFilial('SB1')+SD1->D1_COD, 'B1_CLVL')
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_VALOR"   )
					aColsC6[nAcols,nCntFor] :=   A410Arred((SD1->D1_TOTAL-SD1->D1_VALDESC),"C6_VALOR")
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_LOCAL"   )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_LOCAL
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_TES"     )
					aColsC6[nAcols,nCntFor] :=   Posicione('SB1',1,xFilial('SB1')+SD1->D1_COD,'B1_TS')
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_CF"  	   )
					aColsC6[nAcols,nCntFor] :=   Posicione('SF4',1,xFilial('SB1')+Posicione('SB1',1,xFilial('SB1')+SD1->D1_COD,'B1_TS'),'F4_CF')
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_D1DOC"   )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_DOC
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_D1SERIE" )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_SERIE
				Case ( Alltrim(aHeadC6[nCntFor,2]) == "C6_D1ITEM"  )
					aColsC6[nAcols,nCntFor] :=   SD1->D1_ITEM
				OtherWise
					aColsC6[nAcols,nCntFor] := Criavar(Alltrim(aHeadC6[nCntFor,2]))
			Endcase
		Next nCntFor
	Endif

	//dados das notas de origem
	If Ascan(aItOrigem, {|x| x[1]+x[2] == SD1->D1_SERIORI+SD1->D1_NFORI}) <= 0
		aadd(aItOrigem, {SD1->D1_SERIORI, SD1->D1_NFORI }) //D1_ITEMORI
	EndIf

	SD1->(DbSkip()	)
Enddo

IncProc('Inicializando dados do cabecalho')	//'Inicializando dados do cabecalho'
RegToMemory( "SC5", .T., .F. ) //Inicializa desta forma para criar uma nova instancia de variaveis private 
SA1->(DbSetOrder(1))
SA1->(DbSeek(xFilial()+SF1->F1_FORNECE+SF1->F1_LOJA))
DbSelectArea("SC5")

M->C5_NUM      :=  Criavar('C5_NUM',.T.)
M->C5_TIPO	   :=  "N" //Normal
M->C5_TIPOCLI  :=  SA1->A1_TIPO
M->C5_LOJAENT  :=  SA1->A1_LOJA
M->C5_TABELA   :=  SA1->A1_TABELA
M->C5_MOEDA    :=  SF1->F1_MOEDA
M->C5_CLIENTE  :=  SA1->A1_COD
M->C5_CONDPAG  := cCondPag //-> parametro para condição padrão de nf avulsa de devolução.
M->C5_TPFRETE  := 'S' //-> S - Sem Frete
M->C5_INDPRES  := '1' //-> 1 - Presencial

If SC5->(FieldPos("C5_CLIENT")) > 0
	M->C5_CLIENT  :=  SA1->A1_COD
EndIf

M->C5_LOJACLI  :=  SA1->A1_LOJA
M->C5_TIPOREM  :=  '0'
M->C5_DOCGER   :=  '1'

If SC5->(FieldPos("C5_XNOME")) > 0
	M->C5_XNOME := POSICIONE("SA1",1,XFILIAL("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_NOME")
EndIf
If SC5->(FieldPos("C5_XDOCSD1")) > 0
	M->C5_XDOCSD1 := SF1->F1_DOC
EndIf
If SC5->(FieldPos("C5_XSERSD1")) > 0
	M->C5_XSERSD1 := SF1->F1_SERIE
EndIf

If SC5->(FieldPos("C5_MENNOTA")) > 0
	
	DbSelectArea("SF2")
	SF2->(DbSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
	For nX:=1 to Len(aItOrigem)
		If SF2->(DbSeek(xFilial("SF2")+aItOrigem[nX][2]+aItOrigem[nX][1])) .and. SF2->F2_TIPO = "N"
			if !empty(cMenFis)
				cMenFis += ", "
			endif
			cMenFis += "REF NF: "+SF2->F2_DOC+"/"+SF2->F2_SERIE+" "
		EndIf
	Next nX

	If !Empty(cMenFis)
		M->C5_MENNOTA := Padr(AllTrim(cMenFis), TamSx3("C5_MENNOTA")[1])
	EndIf

EndIf

aCols    := aColsC6
aHeader  := aHeadC6
aColsC6  := {}
CurLen   := 70 - Len(aHeader)
nPosAtu  := 0
nPosAnt  := 9999
nColAnt  := 9999

//+------------------------------------------------------+
//¦ Variaveis Utilizadas pela Funcao a410Inclui          ¦
//+------------------------------------------------------+
Pergunte("MTA410",.F.)
dbSelectArea("SC5")
ALTERA := .F.
INCLUI := .T.
IncProc('Generando Pedido')	//'Generando Pedido'
cCadAux  := cCadastro
cCadastro := OemToAnsi("Pedido de Venda") //+ "Remito"

nPValDesc := aScan(aHeader,{|x| AllTrim(x[2])=="C6_VALDESC"})

//atualiza o % de desconto e os totalizadores
For nX:=1 to Len(aCols)
	n := nX
	A410MultT("C6_VALDESC",aCols[n][nPValDesc])
Next nX

If a410Inclui(Alias(),Recno(),3,.T.) == 1
	Reclock('SF1',.F.)
	Replace F1_PEDVEND	With	SC5->C5_NUM
	MsUnLock()
	nRecNoSC5 := SC5->(RecNo())
Endif
cCadastro   := cCadAux
SetFunName(cFNameAtual)

Return nRecNoSC5

//
//Rotina para gerar liberacoes manuais de cred. e estoque
//
Static Function LibCred()
Local aArea     := GetArea()
Local cCondicao := ""
Local bCondicao
Local lRet := .T.
	
cCondicao := "C9_FILIAL=='"+xFilial("SC9")+"'.And."
cCondicao += "((C9_BLEST<>'  '.And.C9_BLEST<>'10').Or."
cCondicao += "(C9_BLCRED<>'  '.And.C9_BLCRED<>'10').Or."
cCondicao += "C9_BLWMS=='03').And."
cCondicao += "C9_PEDIDO=='"+SC5->C5_NUM+"'"

dbSelectArea("SC9")
// limpo os filtros da SC9
SC9->(DbClearFilter())

// executo o filtro na SC9
bCondicao 	:= "{|| " + cCondicao + " }"
SC9->(DbSetFilter(&bCondicao,cCondicao))

// vou para a primeira linha
SC9->(DbGoTop())

If SC9->( !Eof() )
	lRet := A456LibMan("SC9")
EndIf

// limpo os filtros da SC9
SC9->(DbClearFilter())

RestArea(aArea)

Return lRet
