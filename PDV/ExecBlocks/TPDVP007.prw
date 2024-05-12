#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVP007
Customiza��o da defini��o do tipo emiss�o da venda, "Cupom ou Nota?". (LJ7087)

Seu retorno deve ser um num�rico de 0 a 2, onde:
0 = � definido com a apresenta��o da pergunta (padr�o)
1 = Emiss�o de CF ou NFC-e (sem a apresenta��o da pergunta)
2 = Emiss�o de Nota Fiscal (sem a apresenta��o da pergunta)


****** Regra para Emiss�o NFe ou NFCe no PDV ******

Campo a ser criado:
"Gera NFe ou NFCe no PDV" = "A1_XTIPONF"
-> conte�do "NFe" ou "NFCe" ou "Em branco"
-> inicialmente, como esse campo A1_XTIPONF ser� criado, todos os clientes estar�o com conte�do igual a "Em branco"

Obs.: Quando o campo A1_XTIPONF estiver com conte�do "Em branco", faz a seguinte valida��o:
1) quando cliente � "CNPJ" sempre emite NFe
2) quando cliente � "CPF" e possui inscri��o estadual emite NFe
3) quando cliente � "CPF" e n�o possui inscri��o estadual emite NFCe

As regras gerais ficam:

1) Se cliente � "CNPJ"

1.a) A1_XTIPONF == "NFCe"
-> emite NFCe
1.b) A1_XTIPONF == "NFe" ou "Em branco"
-> emite NFe

2) Se cliente � "CPF"

2.a) A1_XTIPONF == "NFe"
-> emite NFe
2.b) A1_XTIPONF == "NFCe"
-> emite NFCe
3.c) A1_XTIPONF == "Em branco" e cliente possui inscri��o estadual
-> emite NFe
4.d) A1_XTIPONF == "Em branco" e cliente n�o possui inscri��o estadual
-> emite NFCe

Campo a ser criado "Gera NFe ou NFCe no PDV"
Campo: A1_XTIPONF
Tipo: 1 - Caracter
Tamanho: 1
Formato: @!
Titulo: NFe / NFCe?
Descricao: Gera NFe ou NFCe no PDV?
Lista de Op��es: 1=NFe;2=NFCe

@author thebr
@since 26/11/2018
@version 1.0
@return Nil

@type function
/*/
user function TPDVP007(cCliente, cLoja, lLabel)

	Local aArea  	:= GetArea()
	Local aAreaSA1  := SA1->(GetArea())
	Local lConsumidor 	:= .F.
	Local nTPDoc 	:= 1 //0 = Verifica emissao (padr�o) / 1 = Emiss�o de CF ou NFC-e / 2 = Emissao de nota
	Local lNfAcobert  	:= SuperGetMv("MV_XNFACOB",.F.,.F.) //Permite emitir NF-e de acobertado (NF-e sobre NFC-e)
	Local nContigencia	:= SuperGetMv("MV_XNFCONT",.F.,0) //Permite forcar a emissao de NF-e em todas as vendas (contingencia)
	Local lU52TipoNf	:= .F.
	Local nTpU52		:= 0
	Local nChangeTpNf	:= 0

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).

	Default cCliente 	:= SL1->L1_CLIENTE
	Default cLoja 		:= SL1->L1_LOJA
	Default lLabel		:= .F.

	//Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
	If !lMvPosto
		Return 0 //0 = Verifica emissao (padr�o)
	EndIf

	//-- Caso em Cuiaba que parou NFC-e, criamos esse parametro para forcar indepente a regra
	If nContigencia > 0
	 	nTPDoc := nContigencia
		//Conout("MV_XNFCONT: " + Str(nTPDoc,1) + " FORCADO EM CONTIGENCIA TECNICA!" )
		Return nTPDoc
	EndIf
	
	dbSelectArea("U52")
	lU52TipoNf := FWModeAccess("U52")=="E" .AND. U52->(FieldPos("U52_TIPONF"))>0 //se U52 � exclusiva e se exite campo, habilito olhar por filial

	lConsumidor := (AllTrim(cCliente)+AllTrim(cLoja)) == (Alltrim(GetMV("MV_CLIPAD"))+AllTrim(GetMV("MV_LOJAPAD")))

	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbSeek(xFilial("SA1") + cCliente + cLoja))

	//verifico se cliente tem regra espec�fica para a filial
	if lU52TipoNf
		U52->(DbSetOrder(1)) //U52_FILIAL+U52_CODCLI+U52_LOJA+U52_GRPVEN+U52_CLASSE+U52_SATIV1
		if U52->(DbSeek(xFilial("U52")+SA1->A1_COD+SA1->A1_LOJA )) .AND. !empty(U52->U52_TIPONF)
		elseif !empty(SA1->A1_GRPVEN) .AND. U52->(DbSeek(xFilial("U52")+space(tamsx3("U52_CODCLI")[1])+space(tamsx3("U52_LOJA")[1])+SA1->A1_GRPVEN )) .AND. !empty(U52->U52_TIPONF)
		elseif !empty(SA1->A1_XCLASSE) .AND. U52->(DbSeek(xFilial("U52")+space(tamsx3("U52_CODCLI")[1])+space(tamsx3("U52_LOJA")[1])+space(tamsx3("U52_GRPVEN")[1])+SA1->A1_XCLASSE )) .AND. !empty(U52->U52_TIPONF)
		elseif !empty(SA1->A1_SATIV1) .AND. U52->(DbSeek(xFilial("U52")+space(tamsx3("U52_CODCLI")[1])+space(tamsx3("U52_LOJA")[1])+space(tamsx3("U52_GRPVEN")[1])+space(tamsx3("U52_CLASSE")[1])+SA1->A1_SATIV1 )) .AND. !empty(U52->U52_TIPONF)
		endif
		if U52->(!eof()) .AND. U52->(!bof())  .AND. !empty(U52->U52_TIPONF)
			if U52->U52_TIPONF == "2" //U52_TIPONF == "NFCe"
				nTpU52 := 1 //-> emite NFCe
			elseif U52->U52_TIPONF == "1" //U52_TIPONF == "NFe"
				nTpU52 := 2 //-> emite NFe
			endif
			if nTpU52 > 0
				nTPDoc := nTpU52
			endif
		endif
		
	endif

	If nTpU52 == 0 .AND. SA1->(FieldPos("A1_XTIPONF")) > 0 //garanto a existencia do campo

		//Se cliente � "CNPJ" (pessoa juridica)
		If SA1->A1_PESSOA == 'J'

			//A1_XTIPONF == "NFCe"
			If SA1->A1_XTIPONF == "2" .OR. lConsumidor .OR. (Empty(SA1->A1_XTIPONF) .AND. lNfAcobert)
				nTPDoc := 1 //-> emite NFCe
			Else
				nTPDoc := 2 //-> emite NFe
			EndIf

		Else //Se cliente � "CPF" (pessoa fisica)

			//A1_XTIPONF == "NFe"
			If SA1->A1_XTIPONF == "1" .AND. !lConsumidor
				nTPDoc := 2 //-> emite NFe

			//A1_XTIPONF == "NFCe"
			ElseIf SA1->A1_XTIPONF == "2" .OR. lConsumidor .OR. (Empty(SA1->A1_XTIPONF) .and. lNfAcobert)
				nTPDoc := 1 //-> emite NFCe

			//A1_XTIPONF == "Em branco" e cliente possui inscri��o estadual
			ElseIf !Empty(SA1->A1_INSCR) .and. !("ISENT" $ AllTrim(SA1->A1_INSCR)) .and. !lConsumidor
				nTPDoc := 2 //-> emite NFe

			//A1_XTIPONF == "Em branco" e cliente n�o possui inscri��o estadual (ou isento)
			Else
				nTPDoc := 1 //-> emite NFCe
			EndIf
		EndIf
	endif

	//Alert(iif(nTPDoc==1, "Emite NFCe", "Emite NFe"))
	
	//Se est� vindo do ponto de entrada, verifico se usuario modificou o tipo na tela do PDV
	If !lLabel
		nChangeTpNf := U_TPDVP08T()
		if nChangeTpNf > 0 .AND. nChangeTpNf <> nTPDoc
			nTPDoc := nChangeTpNf
		endif
	endif

	//TODO - NF-e: quando TSS OFF-LINE
	If !IsBlind() .and. nTPDoc == 2 //-> emite NFe
		If !lLabel //n�o � do Label: "Tp.Doc: " / n�o � do ajuste de caracteres especiais para NFC-e
			lPergNFCe := SuperGetMv("MV_XPENFCE",.F.,.F.) //ativa pergunta: N�o ser� poss�vel emitir NF-e, deseja emitir NFC-e? (ambiente com TSS OFF-LINE)
			cUrl := SuperGetMv("MV_XURLTSS",.F.,"") //URL do TSS ON-LINE - "http://192.168.1.246:8092"
			If lPergNFCe ; 
				.and. !Empty(cUrl) 
				If !TestComunicacao(cUrl) //faz o teste de comunica��o com o TSS da RETAGUARDA (TSS ON-LINE)
					If MsgYesNo("O TSS ON-LINE n�o esta respondendo, n�o ser� possivel emitir NF-e. Deseja emitir NFC-e?","ATEN��O: NF-e")
						nTPDoc := 1 //-> emite NFCe
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	RestArea(aAreaSA1)
	RestArea(aArea)

Return nTPDoc

//Faz o teste de comunica��o com o TSS da RETAGUARDA (TSS ON-LINE)
Static Function TestComunicacao(cUrl)
Local	oWS			:=	Nil
Local	lRetorno	:=	.T.

	//������������������������������������������������������������������������Ŀ
	//�Verifica se o servidor da Totvs esta no ar                              �
	//��������������������������������������������������������������������������
	oWs := WsSpedCfgNFe():New()
	oWs:cUserToken 	:= 	AllTrim("TOTVS")
	oWS:_URL 		:= 	AllTrim(cUrl)+"/SPEDCFGNFe.apw"
	If !oWs:CFGCONNECT()
		lRetorno 	:= 	.F.
	EndIf

Return(lRetorno)
