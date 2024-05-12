#include 'protheus.ch'
#include 'parmtype.ch'
#include 'poscss.ch'
#include "topconn.ch"
#include "TOTVS.CH"

/*/{Protheus.doc} TRETE031
Rotina que faz a transferência dos créditos de outras filiais.

@author Pablo Cavalcante
@since 07/05/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETE031(aNCCIt)

Local aArea 	:= GetArea()
Local aAreaSE1 	:= SE1->(GetArea())
Local lRet      := .F.
Local aRet      := {}
Local _cChvTit	:= ""

Default aNCCIt  := {}

	aRet := aClone(aNCCIt)
		
	//Conout("TRETE31B - INICIO - "+DtoC(Date())+" "+Time())
	BeginTran() //controle de transação
	//Conout("TRETE31B >> Controle de transação")
	//conout("		 >> aNCCIt - "+U_XtoStrin(aNCCIt))

	DbSelectArea("SE1")
	If aRet[1]
		
		If AllTrim(cFilAnt) <> AllTrim(aRet[14])
	
			//Conout("TRETE31B >> Posiciono no titulo pelo RecNo")
			SE1->(DbGoTo(aRet[5])) //posiciono no titulo pelo RecNo
			If SE1->(!Eof())
	
				// AJUDA:FIN62003  
				// Titulos que tenham solicitações de transferências em aberto, 
				// não podem ser excluidos, alterados, baixados ou faturados.
				If !Empty(SE1->E1_NUMSOL)
					RecLock("SE1",.F.)
						SE1->E1_NUMSOL := ""
					SE1->(MsUnlock())
				EndIf
	
				_cChvTit := SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) //backup da chave do titulo
				//Conout("TRETE31B >> Titulo: <E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO> - <"+SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)+">")
				//Conout("TRETE31B >> Verifica se o titulo é de outra filial, caso sim, inicia o processo de transferencia")
				If xFilial("SE1") <> SE1->E1_FILIAL //verifica se o titulo é de outra filial, caso sim, inicia o processo de transferencia
	
					If AllTrim(SE1->E1_TIPO) == 'RA' .OR. (SE1->E1_VALOR <> SE1->E1_SALDO) //caso seja RA, nao realiza a transferencia, pois a transf. de RA gera SE5 Pagar e Receber
						//Conout("TRETE31B >> Executa a transferencia do RA para a filial corrente")
						lRet := U_TRETE31C(aRet[5],@_cChvTit) //Executa a transferencia do RA para a filial corrente
					Else
						//Conout("TRETE31B >> Executa a tranferencia do NCC para a filial corrente")
						cHistFa620 := "UTILIZACAO DE CREDITO NO PDV"
						lRet := U_TRETE31D(aRet[5],cHistFa620,@_cChvTit) //Executa a tranferencia do NCC para a filial corrente
					EndIf
	
					//Conout("TRETE31B >> _cChvTit - <E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO> - <"+_cChvTit+">")
					SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
					If lRet .and. SE1->(DbSeek(xFilial("SE1")+_cChvTit)) //ajusta o array aRet, como o novo titulo transferido para a filial corrente
						//Conout("TRETE31B >> Ajusta o array aRet, como o novo titulo transferido para a filial corrente")
						/*  array aNccItens (Creditos do Venda Assistida)
							Posicoes de aNCCs
						
							aNCCs[x,1]  = .F.	// Caso a NCC seja selecionada, este campo recebe TRUE		 
							aNCCs[x,2]  = SE1->E1_SALDO  
							aNCCs[x,3]  = SE1->E1_NUM		
							aNCCs[x,4]  = SE1->E1_EMISSAO
							aNCCs[x,5]  = SE1->(Recno()) 
							aNCCs[x,6]  = SE1->E1_SALDO
							aNCCs[x,7]  = SuperGetMV("MV_MOEDA1")
							aNCCs[x,8]  = SE1->E1_MOEDA
							aNCCs[x,9]  = SE1->E1_PREFIXO	
							aNCCs[x,10] = SE1->E1_PARCELA	 
							aNCCs[x,11] = SE1->E1_TIPO
							aNCCs[x,12] = SE1->E1_XPLACA
							aNCCs[x,13] = SE1->E1_XMOTOR
							aNCCs[x,14] = SE1->E1_FILIAL
							aNCCs[x,15] = SE1->E1_XCODBAR
						*/
			  			aRet[2]  := SE1->E1_SALDO
			  			aRet[3]  := SE1->E1_NUM
			  			aRet[4]  := SE1->E1_EMISSAO
						aRet[5]  := SE1->(RecNo())
			  			aRet[6]  := SE1->E1_SALDO
			  			aRet[8]  := SE1->E1_MOEDA
			  			aRet[9]  := SE1->E1_PREFIXO
			  			aRet[10] := SE1->E1_PARCELA
						aRet[11] := SE1->E1_TIPO
						aRet[14] := SE1->E1_FILIAL
	
						lRet := .T.
					EndIf
				Else //ja pertence a mesma filial
					aRet[14] := SE1->E1_FILIAL
					lRet := .T.
				EndIf
				
			EndIf
			
		Else //ja pertence a mesma filial
			lRet := .T.
		EndIf
		
	EndIf
	

	If !lRet //se ocorreu algum erro, restauro o array de creditos
		aRet := aClone(aNCCIt)
		DisarmTransaction()
		//Conout("TRETE31B >> Aborta transação")
	Else
		//Conout("TRETE31B >> Finaliza transação")
	EndIf
	EndTran()

	//Conout("TRETE31B - FIM - "+DtoC(Date())+" "+Time())

RestArea(aAreaSE1)
RestArea(aArea)

Return({aRet,lRet})

//
// Função de transerencia de RA para outra filial
//
User Function TRETE31C( _Rec, _cChv /*E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO*/ )
Local lRet := .F.

Local aArea     := GetArea()
Local aAreaSM0  := SM0->(GetArea())
Local aAreaSA2  := SA2->(GetArea())
Local aAreaSA1  := SA1->(GetArea())
Local aAreaSE1  := SE1->(GetArea())
Local cNatNcc  	:= SuperGetMV( "MV_XNATTNC", .T./*lHelp*/, "OUTROS" /*cPadrao*/) //natureza da transferencia de credito NCC (na filial de destino do credito)
Local nRecNew	:= 0

Default _Rec	:= 0
Default _cChv	:= ""

Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

//Conout("TRETE31B >> TRETE31C - INICIO - "+DtoC(Date())+" "+Time())
//Conout("TRETE31B >> TRETE31C >> Função de transerencia de RA para outra filial")

DbSelectArea("SE1")
SE1->(DbGoTo( _Rec ))
If SE1->(!Eof())

	//Conout("TRETE31B >> TRETE31C >> Cria o titulo de NCC referente ao valor do RA, na filial corrente")
	//cE1_NUM 	:= SE1->E1_NUM
	//cE1_PARCELA := SE1->E1_PARCELA

	//_aAreaSE1 := SE1->(GetArea())
	//SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	//M->E1_NUM := SE1->E1_NUM
	//If SE1->(DbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+"NCC")) .OR. !FreeForUse("SE1",SE1->E1_NUM)
		cE1_NUM 	:= UNEXTSXE("SE1","E1_NUM",xFilial("SE1"),,"E1_PREFIXO = '"+SE1->E1_PREFIXO+"' .and. E1_PARCELA = '001' .and. E1_TIPO = 'NCC'",)
		cE1_PARCELA := "001"
	//EndIf
	//SE1->(DbGoTo( _Rec ))
	//RestArea(_aAreaSE1)

	aFin040 := {}
	AADD(aFin040, {"E1_FILIAL"	,xFilial("SE1")		,Nil } )
	AADD(aFin040, {"E1_PREFIXO"	,SE1->E1_PREFIXO    ,Nil } )
	AADD(aFin040, {"E1_NUM"		,cE1_NUM        	,Nil } )
	AADD(aFin040, {"E1_PARCELA"	,cE1_PARCELA		,Nil } )
	AADD(aFin040, {"E1_TIPO"	,"NCC"      		,Nil } )
	AADD(aFin040, {"E1_NATUREZ"	,cNatNcc			,Nil } )
	AADD(aFin040, {"E1_CLIENTE"	,SE1->E1_CLIENTE	,Nil } )
	AADD(aFin040, {"E1_LOJA"	,SE1->E1_LOJA		,Nil } )
	AADD(aFin040, {"E1_EMISSAO"	,dDataBase			,Nil } )
	AADD(aFin040, {"E1_VENCTO"	,dDataBase			,Nil } )
	AADD(aFin040, {"E1_VENCREA"	,DataValida(dDataBase)	,Nil } )
	AADD(aFin040, {"E1_VALOR"	,SE1->E1_SALDO		,Nil } )
	AADD(aFin040, {"E1_HIST"	,"TRANSF. DE "+Alltrim(SE1->E1_TIPO)+" ENTRE COLIG" ,Nil } )
	AADD(aFin040, {"E1_XPLACA"	,SE1->E1_XPLACA		,Nil } )
	AADD(aFin040, {"E1_XMOTOR"	,SE1->E1_XMOTOR		,Nil } )
	AADD(aFin040, {"E1_ORIGEM" 	,"FINA630"			,Nil } )
	AADD(aFin040, {"E1_XFILIAL"	,SE1->E1_XFILIAL	,Nil } )
	AADD(aFin040, {"E1_XPREFIX"	,SE1->E1_XPREFIX	,Nil } )
	AADD(aFin040, {"E1_XNUM"	,SE1->E1_XNUM		,Nil } )
	AADD(aFin040, {"E1_XPARCEL"	,SE1->E1_XPARCEL	,Nil } )
	AADD(aFin040, {"E1_XTIPO"	,SE1->E1_XTIPO		,Nil } )
	AADD(aFin040, {"E1_XCLIENT"	,SE1->E1_XCLIENT	,Nil } )
	AADD(aFin040, {"E1_XLOJA"	,SE1->E1_XLOJA		,Nil } )
	AADD(aFin040, {"E1_XCODBAR"	,SE1->E1_XCODBAR	,Nil } )

	lMsErroAuto := .F. // variavel interna da rotina automatica
	lMsHelpAuto := .F.

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Chama a funcao de gravacao automatica do FINA040                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//Conout("TRETE31B >> TRETE31C >> Execauto da funcao de gravacao automatica do FINA040.")
	MSExecAuto({|x,y| FINA040(x,y)},aFin040,3)

	If lMsErroAuto
		If IsBlind()
			cErroExec := MostraErro("\temp")
	 		//Conout("TRETE31B >> TRETE31C >> ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		Else
			MostraErro()
		EndIf
		lRet := .F.
	Else
		//Conout("TRETE31B >> TRETE31C >> Titulo de NCC gerado com sucesso!")
		//Conout("TRETE31B >> TRETE31C >> Titulo <E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO> - <"+SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)+">")
		nRecNew := SE1->(RecNo())
		lRet 	:= .T.
	EndIf

	DbSelectArea("SE1")
	SE1->(DbGoTo( _Rec ))

	nValor		:= SE1->E1_SALDO
	cE6_FILORIG := SE1->E1_FILIAL
	aTitOr 		:= {SE1->E1_FILIAL,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA} //dados do titulo de origem


	If lRet
		//Conout("TRETE31B >> TRETE31C >> Realiza a baixa do titulo posicionado, na filial corrente")
		lRet := BaiSE1RA() //realiza a baixa do titulo posicionado, na filial corrente
		If lRet
			DbSelectArea("SE1")
			SE1->(DbGoTo( nRecNew ))
			If SE1->(!Eof())
				_cChv := SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)

				//Conout("TRETE31B >> TRETE31C >> Gera o Contas a Pagar e Contas a Receber (acerto entre as filiais/coligatas)")
				//Gera o Contas a Pagar e Contas a Receber (acerto entre as filiais/coligatas)
				If SGeraAcPg(nValor,cE6_FILORIG,aTitOr) //por se tratar de um credito, gera contas a pagar na filial de origem
					If SGeraAcRc(nValor,cE6_FILORIG,aTitOr) //por se tratar de um credito, gera contas a receber na filial de destino
						lRet := .T.
					else
						lRet := .F.
					EndIf
				else
					lRet := .F.
				EndIf

			Else
				lRet := .F.
			EndIf
		EndIf
	EndIf

EndIf

//Conout("TRETE31B >> TRETE31C - FIM")
RestArea(aAreaSE1)
RestArea(aAreaSA1)
RestArea(aAreaSA2)
RestArea(aAreaSM0)
RestArea(aArea)

Return lRet

/*
-----------------------------------------------------------------------------------
BaiSE1RA -> função para baixar o SE1 posicionado
	>> Motivo "TRF" - Transferencia
	>> Banco (caixa) informado nos parametros.
-----------------------------------------------------------------------------------
*/
Static Function BaiSE1RA()
Local aArea		:= GetArea()
Local aAreaSE1	:= SE1->(GetArea())
Local lRet 		:= .F.
Local _aBaixa 	:= {}
Local cBFilAnt 	:= cFilAnt
Local cBkpFunNam := FunName()

Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

//Conout("TRETE31B >> BaiSE1RA - INICIO - "+DtoC(Date())+" "+Time())
//Conout("TRETE31B >> BaiSE1RA >> Função para baixar o SE1 posicionado")

//Conout("TRETE31B >> BaiSE1RA >> Filial corrente <cFilAnt> "+cFilAnt)
//Conout("TRETE31B >> BaiSE1RA >> Filial do titulo <E1_FILIAL> "+SE1->E1_FILIAL)

		cFilAnt := SE1->E1_FILIAL

		_aBaixa := {;
			{"E1_PREFIXO"   ,SE1->E1_PREFIXO		,Nil},;
			{"E1_NUM"       ,SE1->E1_NUM			,Nil},;
			{"E1_PARCELA"   ,SE1->E1_PARCELA		,Nil},;
			{"E1_TIPO"      ,SE1->E1_TIPO			,Nil},;
			{"E1_CLIENTE" 	,SE1->E1_CLIENTE 		,Nil},;
			{"E1_LOJA" 		,SE1->E1_LOJA 			,Nil},;
			{"AUTMOTBX"     ,"TRF" /*-> Motivo da Baixa*/,Nil},;
			{"AUTBANCO"     ,SE1->E1_PORTADO /*cBanco*/,Nil},;
			{"AUTAGENCIA"   ,SE1->E1_AGEDEP/*cAgencia*/,Nil},;
			{"AUTCONTA"     ,SE1->E1_CONTA/*cNumCon*/  ,Nil},;
			{"AUTDTBAIXA"   ,dDataBase				,Nil},;
			{"AUTDTCREDITO" ,dDataBase				,Nil},;
			{"AUTHIST"      ,"TRANSF. DE RA ENTRE COLIG" ,Nil},;
			{"AUTJUROS"     ,0                      ,Nil,.T.},;
			{"AUTVALREC"    ,SE1->E1_SALDO			,Nil}}

		//BeginTran()
		lMsErroAuto := .F.

		//Conout("TRETE31B >> BaiSE1RA >> Execauto da rotina de baixa Fina070")
		SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)					
		MSExecAuto({|x,y| Fina070(x,y)}, _aBaixa, 3) //Baixa conta a receber
		SetFunName(cBkpFunNam)

		If lMsErroAuto
			//DisarmTransaction()
			If IsBlind()
				cErroExec := MostraErro("\temp")
		 		//Conout("TRETE31B >> BaiSE1RA >> ============ ERRO =============")
				//Conout(cErroExec)
				cErroExec := ""
			Else
				MostraErro()
			EndIf
			lRet := .F.
		Else
			lRet := .T.
		EndIf
		//EndTran()

	cFilAnt := cBFilAnt

//Conout("TRETE31B >> BaiSE1RA - FIM")

RestArea(aAreaSE1)
RestArea(aArea)

Return lRet

//
// Gera o Contas a Pagar, de acerto entre coligatas
// >> gera o titulo CLP na filial de origem (filial onde o credito foi originado)
//
Static Function SGeraAcPg(nValor,cFilOrig,aTitOr,cHist)

Local lRet		:= .F.
Local aArea 	:= GetArea()
Local aAreaSM0 	:= SM0->(GetArea())
Local aAreaSA2 	:= SA2->(GetArea())
Local aAreaSE2 	:= SE2->(GetArea())
Local cNum  := ""
Local cParc := ""

Default cHist	:= "TRANSF DA FIL "+cFilOrig+" P/"+cFilAnt+""
Default aTitOr	:= {""/*SE1->E1_FILIAL*/,;
					""/*SE1->E1_PREFIXO*/,;
					UNEXTSXE("SE2","E2_NUM",cFilOrig,,"E2_PREFIXO = '"+SUPERGETMV("MV_XPAGPRE", .F., "CLP", cFilAnt)+"' .AND. E2_PARCELA = '001' .AND. E2_TIPO = '"+SUPERGETMV("MV_XPAGTIP", .F., "DP ", cFilAnt)+"' .AND. E2_FORNECE = '"+SA2->A2_COD+"' .AND. E2_LOJA = '"+SA2->A2_LOJA+"'",)/*SE1->E1_NUM*/,;
					"001"/*SE1->E1_PARCELA*/,;
					""/*SE1->E1_TIPO*/,;
					""/*SE1->E1_CLIENTE*/,;
					""/*SE1->E1_LOJA*/}

Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

//Conout("TRETE31B >> SGeraAcPg - INICIO - "+DtoC(Date())+" "+Time())
//Conout("TRETE31B >> SGeraAcPg >> Gera o Contas a Pagar, de acerto entre coligatas")

	DbSelectArea("SA2")
	DbSetOrder(3) //A2_FILIAL+A2_CGC
	If !SA2->(DbSeek(xFilial("SA2")+SM0->M0_CGC)) //considera que o cadastro de forncedor esta compartilhado
		//Conout("TRETE31B >> SGeraAcPg >> Inclui cadastro de forncedor para o CNPJ " +SM0->M0_CGC)
		RecLock("SA2",.T.)
			SA2->A2_FILIAL 	:= xFilial("SA2")
			SA2->A2_COD  	:= GETSXENUM('SA2','A2_COD')
			SA2->A2_LOJA 	:= "01"
			SA2->A2_INSCR 	:= SM0->M0_INSC
			SA2->A2_CGC  	:= SM0->M0_CGC
			SA2->A2_TIPO 	:= "J"
			SA2->A2_NOME 	:= SM0->M0_NOMECOM
			SA2->A2_NREDUZ 	:= SM0->M0_FILIAL
			SA2->A2_END  	:= SM0->M0_ENDCOB
			SA2->A2_BAIRRO 	:= SM0->M0_BAIRCOB
			SA2->A2_MUN  	:= SM0->M0_CIDCOB
			SA2->A2_EST  	:= SM0->M0_ESTCOB
			SA2->A2_CEP  	:= SM0->M0_CEPCOB
		SA2->(MsUnlock())
	EndIf

	_cFilbkp := cFilAnt
	cFilAnt  := cFilOrig
	SM0->(DbSetOrder(1))
	SM0->(DbSeek(cEmpAnt+cFilAnt)) //cEmpAnt EMPRESA QUE ESTÁ LOGADA e cFilAnt É A FILIAL

	//DbSelectArea("SE2")
	//DbSetOrder(1) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
	//If !SE2->(DbSeek(cFilOrig+SUPERGETMV("MV_XPAGPRE", .F., "CLP", cFilAnt)+aTitOr[03]+aTitOr[04]+SUPERGETMV("MV_XPAGTIP", .F., "DP ", cFilAnt)+SA2->A2_COD+SA2->A2_LOJA))
	//	cNum  := aTitOr[03]
	//	cParc := aTitOr[04]
	//Else
		cNum  := UNEXTSXE("SE2","E2_NUM",cFilOrig,,"E2_PREFIXO = '"+SUPERGETMV("MV_XPAGPRE", .F., "CLP", cFilAnt)+"' .AND. E2_PARCELA = '001' .AND. E2_TIPO = '"+SUPERGETMV("MV_XPAGTIP", .F., "DP ", cFilAnt)+"' .AND. E2_FORNECE = '"+SA2->A2_COD+"' .AND. E2_LOJA = '"+SA2->A2_LOJA+"'",)
		cParc := "001"
	//EndIf

	aTitPag := {}
	aAdd(aTitPag, {"E2_FILIAL"	, cFilOrig						, Nil} )
	aAdd(aTitPag, {"E2_PREFIXO"	, SUPERGETMV("MV_XPAGPRE", .F., "CLP", cFilAnt), NIL} ) //Prefixo de Pagamento entre Coligatas
	aAdd(aTitPag, {"E2_NUM"		, cNum							, NIL} )
	aAdd(aTitPag, {"E2_PARCELA"	, cParc							, NIL} )
	aAdd(aTitPag, {"E2_TIPO"	, SUPERGETMV("MV_XPAGTIP", .F., "DP ", cFilAnt), NIL} ) //Tipo do Titulo de Pagamento entre Coligatas
	aAdd(aTitPag, {"E2_NATUREZ"	, SUPERGETMV("MV_XPAGFIL", .F., "OUTROS", cFilAnt), NIL} ) //Natureza de Pagamento entre Coligatas
	aAdd(aTitPag, {"E2_FORNECE"	, SA2->A2_COD					, NIL} )
	aAdd(aTitPag, {"E2_LOJA"	, SA2->A2_LOJA					, NIL} )
	aAdd(aTitPag, {"E2_EMISSAO"	, dDataBase						, NIL} )
	aAdd(aTitPag, {"E2_VENCTO"	, dDataBase						, NIL} )
	AADD(aTitPag, {"E2_VENCREA"	, DataValida(dDataBase)			, Nil} )
	aAdd(aTitPag, {"E2_VALOR"	, nValor						, NIL} )
	aAdd(aTitPag, {"E2_HIST"	, cHist							, NIL} )
	AADD(aTitPag, {"E2_ORIGEM" 	, "TRETE031"					, Nil} )
	aAdd(aTitPag, {"E2_XFILIAL"	, aTitOr[01]					, NIL} )
	aAdd(aTitPag, {"E2_XPREFIX"	, aTitOr[02]					, NIL} )
	aAdd(aTitPag, {"E2_XNUM"	, aTitOr[03]					, NIL} )
	aAdd(aTitPag, {"E2_XPARCEL"	, aTitOr[04]					, NIL} )
	aAdd(aTitPag, {"E2_XTIPO"	, aTitOr[05]					, NIL} )
	aAdd(aTitPag, {"E2_XCLIENT"	, aTitOr[06]					, NIL} )
	aAdd(aTitPag, {"E2_XLOJA"	, aTitOr[07]					, NIL} )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Chama a funcao de gravacao automatica do FINA050 - Contas a Pagar       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SE2")
	DbSetOrder(1) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
	If !SE2->(DbSeek(cFilOrig+SUPERGETMV("MV_XPAGPRE", .F., "CLP", cFilAnt)+cNum+cParc+SUPERGETMV("MV_XPAGTIP", .F., "DP ", cFilAnt)+SA2->A2_COD+SA2->A2_LOJA))
		//Conout("TRETE31B >> SGeraAcPg >> Execauto da rotina FINA050 - inclusao de contas a pagar, de acerto de coligatas.")

		MSExecAuto({|x,y| FINA050(x,y)}, aTitPag, 3)

	 	cFilAnt := _cFilbkp

		If lMsErroAuto
			DisarmTransaction()
			If IsBlind()
				cErroExec := MostraErro("\temp")
		 		//Conout("TRETE31B >> SGeraAcPg >> ============ ERRO =============")
				//Conout(cErroExec)
				cErroExec := ""
			Else
				MostraErro()
			EndIf
		Else
			lRet := .T.
		EndIf

	EndIf

	cFilAnt := _cFilbkp

//Conout("TRETE31B >> SGeraAcPg - FIM")

RestArea(aAreaSM0)
RestArea(aAreaSA2)
RestArea(aAreaSE2)
RestArea(aArea)

Return(lRet)

//
// Gera o Contas a Receber, de acerto entre coligatas
// >> gera o titulo CLR na filial de destino (filial onde o credito foi transferido)
//
Static Function SGeraAcRc(nValor,cFilOrig,aTitOr,cHist)
Local lRet		:= .F.
Local aArea 	:= GetArea()
Local aAreaSM0 	:= SM0->(GetArea())
Local aAreaSA1 	:= SA1->(GetArea())
Local aAreaSE1 	:= SE1->(GetArea())
Local cNum  := ""
Local cParc := ""

Default cHist	:= "TRANSF DA FIL "+cFilOrig+" P/"+cFilAnt+""
Default aTitOr	:= {""/*SE1->E1_FILIAL*/,;
					""/*SE1->E1_PREFIXO*/,;
					UNEXTSXE("SE1","E1_NUM",xFilial("SE1"),,"E1_CLIENTE = '"+SA1->A1_COD+"' .and. E1_LOJA = '"+SA1->A1_LOJA+"' .and. E1_PREFIXO = '"+SUPERGETMV("MV_XRECPRE", .F., "CLR", cFilOrig)+"' .and. E1_PARCELA = '001' .and. E1_TIPO = '"+SUPERGETMV("MV_XRECTIP", .F., "DP ", cFilOrig)+"'",)/*SE1->E1_NUM*/,;
					"001"/*SE1->E1_PARCELA*/,;
					""/*SE1->E1_TIPO*/,;
					""/*SE1->E1_CLIENTE*/,;
					""/*SE1->E1_LOJA*/}

Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

//Conout("TRETE31B >> SGeraAcRc - INICIO - "+DtoC(Date())+" "+Time())
//Conout("TRETE31B >> SGeraAcRc >> Gera o Contas a Receber, de acerto entre coligatas")

	SM0->(DbSetOrder(1))
	SM0->(DbSeek(cEmpAnt+cFilOrig)) //cEmpAnt EMPRESA QUE ESTÁ LOGADA E cFilOrig É A FILIAL DE ORIGEM

	DbSelectArea("SA1")
	DbSetOrder(3) //A1_FILIAL+A1_CGC
	If !SA1->(DbSeek(xFilial("SA1")+SM0->M0_CGC)) //considera que o cadastro de cliente esta compartilhado
		//Conout("TRETE31B >> SGeraAcRc >> Inclui cadastro de cliente para o CNPJ " +SM0->M0_CGC)
		RecLock("SA1",.T.)
			SA1->A1_FILIAL 	:= xFilial("SA1")
			SA1->A1_COD  	:= GETSXENUM('SA2','A2_COD')
			SA1->A1_LOJA 	:= "01"
			SA1->A1_INSCR	:= SM0->M0_INSC
			SA1->A1_CGC  	:= SM0->M0_CGC
			SA1->A1_TIPO 	:= "F"
			SA1->A1_PESSOA 	:= "J"
			SA1->A1_NOME 	:= SM0->M0_NOMECOM
			SA1->A1_NREDUZ 	:= SM0->M0_FILIAL
			SA1->A1_END  	:= SM0->M0_ENDCOB
			SA1->A1_BAIRRO 	:= SM0->M0_BAIRCOB
			SA1->A1_MUN  	:= SM0->M0_CIDCOB
			SA1->A1_EST  	:= SM0->M0_ESTCOB
			SA1->A1_CEP  	:= SM0->M0_CEPCOB
		SA1->(MsUnlock())
	EndIf

	RestArea(aAreaSM0) //volto o SM0

	//DbSelectArea("SE1")
	//SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	//If !SE1->(DbSeek(xFilial("SE1")+SUPERGETMV("MV_XRECPRE", .F., "CLR", cFilOrig)+aTitOr[03]+aTitOr[04]+SUPERGETMV("MV_XRECTIP", .F., "DP ", cFilOrig)))
	//	cNum  := aTitOr[03]
	//	cParc := aTitOr[04]
	//Else
		cNum  := UNEXTSXE("SE1","E1_NUM",xFilial("SE1"),,"E1_PREFIXO = '"+SUPERGETMV("MV_XRECPRE", .F., "CLR", cFilOrig)+"' .and. E1_PARCELA = '001' .and. E1_TIPO = '"+SUPERGETMV("MV_XRECTIP", .F., "DP ", cFilOrig)+"'",)
		cParc := "001"
	//EndIf

	aFin040 := {}
	AADD(aFin040, {"E1_FILIAL"	, xFilial("SE1")				,Nil } )
	AADD(aFin040, {"E1_PREFIXO"	, SUPERGETMV("MV_XRECPRE", .F., "CLR", cFilOrig), Nil } ) //Prefixo de Recebimento entre Coligatas

	AADD(aFin040, {"E1_NUM"		, cNum							,Nil } )
	AADD(aFin040, {"E1_PARCELA"	, cParc							,Nil } )

	AADD(aFin040, {"E1_TIPO"	, SUPERGETMV("MV_XRECTIP", .F., "DP ", cFilOrig), Nil } ) //Tipo do Titulo de Recebimento entre Coligatas
	AADD(aFin040, {"E1_NATUREZ"	, SUPERGETMV("MV_XRECFIL", .F., "OUTROS", cFilOrig), Nil } ) //Natureza de Recebimento entre Coligatas
	AADD(aFin040, {"E1_CLIENTE"	, SA1->A1_COD					,Nil } )
	AADD(aFin040, {"E1_LOJA"	, SA1->A1_LOJA					,Nil } )
	AADD(aFin040, {"E1_EMISSAO"	, dDataBase						,Nil } )
	AADD(aFin040, {"E1_VENCTO"	, dDataBase						,Nil } )
	AADD(aFin040, {"E1_VENCREA"	, DataValida(dDataBase)			,Nil } )
	AADD(aFin040, {"E1_VALOR"	, nValor						,Nil } )
	AADD(aFin040, {"E1_HIST"	, cHist							,Nil } )
	AADD(aFin040, {"E1_ORIGEM" 	, "TRETE031"					,Nil } )
	AADD(aFin040, {"E1_XFILIAL"	, aTitOr[01]					,Nil } )
	AADD(aFin040, {"E1_XPREFIX"	, aTitOr[02]					,Nil } )
	AADD(aFin040, {"E1_XNUM"	, aTitOr[03]					,Nil } )
	AADD(aFin040, {"E1_XPARCEL"	, aTitOr[04]					,Nil } )
	AADD(aFin040, {"E1_XTIPO"	, aTitOr[05]					,Nil } )
	AADD(aFin040, {"E1_XCLIENT"	, aTitOr[06]					,Nil } )
	AADD(aFin040, {"E1_XLOJA"	, aTitOr[07]					,Nil } )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Chama a funcao de gravacao automatica do FINA040 - Contas a Receber     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SE1")
	SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	If !SE1->(DbSeek(xFilial("SE1")+SUPERGETMV("MV_XRECPRE", .F., "CLR", cFilOrig)+cNum+cParc+SUPERGETMV("MV_XRECTIP", .F., "DP ", cFilOrig)))

		//Conout("TRETE31B >> SGeraAcRc >> Execauto da rotina FINA040 - inclusao de contas a receber, de acerto de coligatas.")
		MSExecAuto({|x,y| FINA040(x,y)}, aFin040, 3)

		If lMsErroAuto
			DisarmTransaction()
			If IsBlind()
				cErroExec := MostraErro("\temp")
		 		//Conout("TRETE31B >> SGeraAcRc >> ============ ERRO =============")
				//Conout(cErroExec)
				cErroExec := ""
			Else
				MostraErro()
			EndIf
		Else
			lRet := .T.
		EndIf
		//EndTran() //finaliza toda a operação

	EndIf

//Conout("TRETE31B >> SGeraAcRc - FIM")

RestArea(aAreaSM0)
RestArea(aAreaSA1)
RestArea(aAreaSE1)
RestArea(aArea)

Return(lRet)

//
// Função automatica para inclusao de solicitacao de tranferencia de titilo entre as filiais
//
User Function TRETE31D( _Rec , cHistFa620 , _Chave )
Local nValor    := 0 //SE1->E1_SALDO
Local lRet      := .F.
Local aSolict	:= {}
Local cChaveSE6 := ""
Local lContinua := .T.
Local cNSolAux := ""

Local aArea     := GetArea()
Local aAreaSE6  := SE6->(GetArea())

//variaveis para serem passadas para a function Fa620Auto
Local nRecSe1		:= _Rec                           //Recno do titulo Principal
Local cFilDest		:= xFilial("SE1")                 //Filial de Destino
Local lAprov		:= .F.                            //Executa aprovação da transferência automaticamente
Local lMsgErro		:= .F. 						      //Apresenta mensagem de erro "Mostraerro( )"
Local cFilBkp 		:= cFilAnt

Default cHistFa620  := "OPERCACAO DE SAQUE NO CAIXA"  //Histórico da transferência

Private INCLUI  := .T. // Variavel necessária para o ExecAuto identificar que se trata de uma inclusão
Private ALTERA  := .F. // Variavel necessária para o ExecAuto identificar que se trata de uma inclusão

lMsErroAuto := .F. // variavel interna da rotina automatica
//lMsHelpAuto := .F.

DbSelectArea("SE1")
SE1->(DbGoTo(nRecSe1))
aTitOr := {SE1->E1_FILIAL,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA}
nValor := SE1->E1_SALDO

//Conout("TRETE31B >> TRETE31D - INICIO - "+DtoC(Date())+" "+Time())
//BeginTran()
cChaveSE6 := xFilial("SE6")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_FILIAL)
cNSolAux := SE1->E1_NUMSOL

//Danilo: eliminando numerações ja utilizadas
DbSelectArea("SE6")
SE6->(DbSetOrder(3))
While .T.
	cNumSol := GetSx8Num("SE1","E1_NUMSOL","E1_NUMSOL" + cEmpAnt)
	if SE6->(DbSeek(xFilial("SE6")+cNumSol))
		ConfirmSx8()
	else
		ROLLBACKSX8()
		EXIT
	endif
enddo

//se por acaso encontrar a transferencia, exclui para tentar refazer
DbSelectArea("SE6")
SE6->(DbSetOrder(4)) //E6_FILIAL+E6_PREFIXO+E6_NUM+E6_PARCELA+E6_TIPO+E6_FILORIG
If SE6->(DbSeek(cChaveSE6))
	if Reclock("SE6", .F.)
		SE6->(DbDelete())
		SE6->(MsUnlock())
		if !empty(cNSolAux)
			Reclock("SE1",.F.)
				SE1->E1_NUMSOL := ""
			SE1->(MsUnlock())
		Endif
	Else
		//Conout("TRETE31B >> TRETE31D >> Ja existe <SE6 - Solicitacao de Transferencia> cadastrada para esse titulo.")
		lContinua := .F.
	EndIf
endif

if lContinua
	//Conout("TRETE31B >> TRETE31D >> Execauto da rotina Fa620Auto - rotina automática de solicitação de transferência de débito.")
	Fa620Auto(nRecSe1, cFilDest, cHistFa620, lAprov, lMsgErro)

	If lMsErroAuto
		//DisarmTransaction()
		If IsBlind()
			cErroExec := MostraErro("\temp")
	 		//Conout("TRETE31B >> TRETE31D >> ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		Else
			MostraErro()
		EndIf
	Else
		//SFina630() //realiza a aprovacao da transferencia

		cFilAnt := cFilBkp
		lMsErroAuto := .F.
		//cChaveSE6 	:= SE6->(E6_FILIAL+E6_PREFIXO+E6_NUM+E6_PARCELA+E6_TIPO+E6_FILORIG)

		DbSelectArea("SE6")
		SE6->(DbSetOrder(4)) //E6_FILIAL+E6_PREFIXO+E6_NUM+E6_PARCELA+E6_TIPO+E6_FILORIG
		If SE6->(DbSeek(cChaveSE6))
			aSolict := {{"E6_NUMSOL", SE6->E6_NUMSOL, Nil}} //considera que ja esteja posicionado na Solic. de Transferencia
			//Conout("TRETE31B >> TRETE31D >> Execauto da rotina Fina630 - rotina automática Aprov/Rej. Transf.")
			MSExecAuto({|x,y| Fina630(x,y)}, aSolict, 3)
		Else
			//Conout("TRETE31B >> TRETE31D >> Nao existe <SE6 - Solicitacao de Transferencia> cadastrada para esse titulo.")
			//DisarmTransaction()
			cFilAnt := cFilBkp
			Return(lRet)
		EndIf

		If lMsErroAuto
			//DisarmTransaction()
			If IsBlind()
				cErroExec := MostraErro("\temp")
		 		//Conout("TRETE31B >> TRETE31D >> ============ ERRO =============")
				//Conout(cErroExec)
				cErroExec := ""
			Else
				MostraErro()
			EndIf
		Else

			DbSelectArea("SE6")
			SE6->(DbSetOrder(4)) //E6_FILIAL+E6_PREFIXO+E6_NUM+E6_PARCELA+E6_TIPO+E6_FILORIG
			If SE6->(DbSeek(cChaveSE6))
				_Chave := SE6->(E6_CLIENTE+E6_LOJA+E6_PREFIXO+E6_NUM+E6_PARCDES+E6_TIPO)
				//Conout("TRETE31B >> TRETE31D >> Gera o Contas a Pagar e Contas a Receber (acerto entre as filiais/coligatas)")
				//Gera o Contas a Pagar e Contas a Receber (acerto entre as filiais/coligatas)
				If SGeraAcPg(nValor,SE6->E6_FILORIG,aTitOr) //por se tratar de um credito, gera contas a pagar na filial de origem
					If SGeraAcRc(nValor,SE6->E6_FILORIG,aTitOr) //por se tratar de um credito, gera contas a receber na filial de destino
						lRet := .T.
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	//EndTran()
endif

//Conout("TRETE31B >> TRETE31D - FIM")
cFilAnt := cFilBkp
RestArea(aAreaSE6)
RestArea(aArea)

Return(lRet)


/*  
Função que retorna o próximo para um determinada tabela
OBS.: quando a tabela possui muitos registros, o filtro (dbsetfilter) pode demorar muito tempo
	Exemplo:

		Inicializador do campo UH0_CODIGO:

		Alias: "UH0"
		Campo: "UH0_CODIGO"
		cFilial: xFilial("UH0")
		nTam: 6
		cWhere: "UH0_FIL = '"+CFILANT+"' .AND. UH0_AMBIE = '"+GETMV("MV_LJAMBIE")+"'"
		nIndice: 1

		UNEXTSXE("UH0","UH0_CODIGO",xFilial("UH0"),,"UH0_FIL = '"+CFILANT+"' .AND. UH0_AMBIE = '"+GETMV("MV_LJAMBIE")+"'",)

*/

Static Function UNEXTSXE(_cAlias, _cCampo, _cFilial, _nTam, _cWhere, _nIndic)

Local aArea		:= GetArea()
Local aAreaXXX  := &(_cAlias+"->(GetArea())")
Local cRet		:= ""
Local cChave	:= "UNEXT"+_cAlias
Local cCondicao	:= ""
Private bCondicao

Default _cFilial:= &("xFilial('"+_cAlias+"')")
Default _nTam	:= TamSx3(_cCampo)[1]
Default _cWhere := ""
Default _nIndic := 1

SET DELETED OFF //CONSIDERA DELETADOS

	//preenche filial do alias
	If !Empty(_cFilial)
		_cFilial := &("xFilial('"+_cAlias+"')")
	EndIf

	//filtro da tabela
	If Left(_cAlias,1)<>"S"
		cCondicao := " "+_cAlias+"_FILIAL = '"+_cFilial+"'"
	Else
		cCondicao := " "+right(_cAlias,2)+"_FILIAL = '"+_cFilial+"'"
	Endif

	If !Empty(_cWhere)
		If !Empty(cCondicao)
			cCondicao += " .AND. " + _cWhere
		Else
			cCondicao := " " + _cWhere
		EndIf
	EndIf

	//ordenação da tabela
	&(_cAlias+"->(DbSetOrder("+cValToChar(_nIndic)+"))")

	// limpo os filtros
	&(_cAlias+"->(DbClearFilter())")

	// aplico o filtro
	bCondicao 	:= "{|| " + cCondicao + " }"
	&(_cAlias+'->(DbSetFilter(&bCondicao,"'+cCondicao+'"))')

	// posiciono no primeiro
	&(_cAlias+"->(DbGoTop())")

	// posiciono no último registro
	&(_cAlias+"->(DbGoBottom())")

	// se não existir regitros
	If &(_cAlias+"->(Eof())")//UH0->(Eof())
		cRet := PADL("1",_nTam,"0")
	Else
		// incremento o código do último registro
		cRet := PADL(Soma1(&(_cAlias+"->"+_cCampo)),_nTam,"0")

		// libera todos os nomes reservados pela MayIUseCode
		//FreeUsedCode() --> foi comentado, pois pode limpar a pilha de reservas de outras rotinas
		While !MayIUseCode( cChave + _cFilial + cRet )
			cRet := Soma1(cRet)
		EndDo
	EndIf

	// limpo os filtros da tabela
	&(_cAlias+"->(DbClearFilter())")

SET DELETED ON // DESCONSIDERA DELETADOS
RestArea(aAreaXXX)
RestArea(aArea)

Return(cRet)
