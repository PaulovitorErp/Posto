#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVP020 (LJ7111)
Ponto de entrada para manipular string xml da NFCE

@author thebr
@since 03/09/2019
@version 1.0
@return Nil

@type function
/*/
User Function TPDVP020()

    Local cXmlRet := ParamIxb[1]
    Local cBkpXml := cXmlRet
    Local cFormaFid := ""
    Local nValorFid := 0
    Local nPosPagCard := 0
    Local nPosAux := 0
    Local nPosAux2 := 0
    Local nVlrAux := 0
    Local cTpIntegra 
    Local cCliPad	:= SuperGetMV( "MV_CLIPAD" ,, "000001" )	//cliente padrao
	Local cLojaPad	:= SuperGetMV( "MV_LOJAPAD",, "01" )		//loja padrao
	Local cAdmFid	:= SuperGetMv("MV_XADMFID",,"")
	Local lAju441   := SuperGetMv("MV_XAJR411",,.T.) //Ajusta rejei็ใo 441: Descri็ใo do pagamento obrigat๓ria para meio de pagamento 99
    Local cXMLAux, aGetMvTSS, cMvAmbNFCe

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustํvel (Posto Inteligente).
	//Caso o Posto Inteligente nใo esteja habilitado nใo faz nada...
	If !lMvPosto
		Return cXmlRet
	EndIf
    
    //se tem cartao, verifico se ้ adm do fidelidade (pega ponto) para trocar forma
    if AT('<card>', cXmlRet)> 0 
        
        SL4->(DbSetOrder(1)) //L4_FILIAL+L4_NUM+L4_ORIGEM
        If SL4->( DbSeek( xFilial( "SL4" ) + SL1->L1_NUM ) )
            While SL4->(!EoF()) .AND. SL4->L4_FILIAL + SL4->L4_NUM == SL1->L1_FILIAL + SL1->L1_NUM 
                If SL4->L4_VALOR > 0 .AND. Alltrim(SL4->L4_FORMA) $ 'CC/CD' 
                    //pra saber se teve adm de fidelidade
                    if SubStr(SL4->L4_ADMINIS,1,3) $ cAdmFid
                        nValorFid += SL4->L4_VALOR
                        if !empty(cFormaFid) .AND. cFormaFid <> AllTrim(SL4->L4_FORMA)
                            //Conout("LJ7111 - nใo serแ trocada forma cartao fidelidade. permitido somente para uma forma: CC ou CD")
                            nValorFid := 0
                            EXIT
                        endif
                        cFormaFid := AllTrim(SL4->L4_FORMA)
                    endif
                EndIf
                SL4->( DbSkip() )
            EndDo
        EndIf

        if nValorFid > 0 //se tem adm fid

            //Localizando a TAG 03 ou 04 - CARTAO CREDITO/DEBITO, referente ao valor dessa adm financeira.
            nPosPagCard := AT('<tPag>'+iif(cFormaFid=="CC","03","04"),cXmlRet)
            if nPosPagCard > 0
                While .T.
                    nPosAux := AT('<vPag>',cXmlRet, nPosPagCard)
                    nPosAux2 := AT('</vPag>',cXmlRet, nPosAux)
                    nVlrAux := Val( SubStr(cXmlRet,nPosAux+6, nPosAux2 )  )
                    cTpIntegra := SubStr(cXmlRet, AT('<card><tpIntegra>', cXmlRet, nPosAux2)+17 , 1)
                    if nVlrAux == nValorFid .AND. cTpIntegra == '2' //somente POS
                        //jogo tipo 99 na tag <tpag>
                        cXmlRet := SubStr(cXmlRet,1,nPosPagCard+5) + "99" + SubStr(cXmlRet,nPosPagCard+8)
                        //retiro tags <card>
                        nPosAux := AT('<card>', cXmlRet, nPosPagCard)
                        nPosAux2 := AT('</card>', cXmlRet, nPosPagCard)
                        cXmlRet := SubStr(cXmlRet,1,nPosAux-1) + SubStr(cXmlRet,nPosAux2+7)
                        //Conout("LJ7111 - Trocada forma pagamento XML de cartใo para outros. Adm parametro MV_XADMFID.")
                        EXIT
                    else
                        nPosPagCard := AT('<tPag>'+iif(cFormaFid=="CC","03","04"),cXmlRet,nPosAux2)
                        if nPosPagCard == 0
                            //Conout("LJ7111 - Aborta troca forma fidelidade. Nใo encontrada tag do cartใo fidelidade.")
                            EXIT
                        endif
                    endif
                enddo
            else
                //aborta pois tem algum problema no xml.
                //Conout("LJ7111 - Aborta troca forma fidelidade. Nใo encontrada tag de cartใo para sobrescrever.")
                cXmlRet := cBkpXml
            endif
            
        endif

    endif

    //Tratamento tag <dest> para quando selecionar cliente, ignorar o digitado no campo CPF Motorista
    if AT('<dest>', cXmlRet)> 0

        //Obtemos o AMBIENTE configurado no TSS
        aGetMvTSS := LjGetMVTSS("MV_AMBNFCE","2")
        If aGetMvTSS[1]
            cMvAmbNFCe := SubStr( aGetMvTSS[2], 1, 1 )
        EndIf

        //se informou cliente, vai considerar ele. Ja desconsidero o CGC informado na tela.
        If	SA1->(DbSeek(xFilial("SA1") + SL1->L1_CLIENTE + SL1->L1_LOJA)) ;
            .AND. ((AllTrim(SL1->L1_CLIENTE) + AllTrim(SL1->L1_LOJA)) <> (AllTrim(cCliPad) + AllTrim(cLojaPad))) ;
            .AND. !Empty(SA1->A1_CGC) //.And. (AllTrim(SA1->A1_CGC) <> AllTrim(SL1->L1_CGCCLI))

            //Conout("LJ7111 - Troca tag <dest>, cliente selecionado diferente CGC informado. For็a usar do cliente SA1.")

			//Em ambiente de HOMOLOGACAO, o nome deve ser: NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL
			If cMvAmbNFCe == "2"
				cNome := "NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL"
			Else
				cNome := AllTrim( SA1->A1_NOME )
			EndIf
	
			//
			// X M L
			//
			cXMLAux := "<dest>"
	        
            cCPFCNPJ := AllTrim( SA1->A1_CGC )
			If Len(cCPFCNPJ) < 14
				cXMLAux += "<CPF>" + cCPFCNPJ + "</CPF>"
			Else
				cXMLAux += "<CNPJ>" + cCPFCNPJ + "</CNPJ>"
			EndIf
	
			cXMLAux += 	"<xNome>" + cNome + "</xNome>"
	
			//Para vendas acima de R$10.000, ้ necessแrio informar o grupo <enderDest>.
			//Como sใo tags obrigat๓rias, antes de preenche-las, validamos se todos os campos estใo preenchidos
			If !Empty(SA1->A1_END) .AND. !Empty(SA1->A1_BAIRRO) .AND. !Empty(SA1->A1_EST) .AND. !Empty(SA1->A1_COD_MUN)
	
				//retorna [1]xLgr [2]nro(N) [3]nro(C) [4](xCpl), sendo que no A1_END, 
				//o n๚mero deve ser separado por virgula e o complemento por um espa็o em branco
				If ExistFunc("LjFiGetEnd")
					aDest := LjFiGetEnd( AllTrim(SA1->A1_END), Nil, .T. )
					aFone := LjFiGetTel(SA1->A1_DDI + SA1->A1_DDD + SA1->A1_TEL)
				Else
					aDest := FisGetEnd( AllTrim(SA1->A1_END) )
					aFone := FisGetTel(SA1->A1_DDI + SA1->A1_DDD + SA1->A1_TEL)
				EndIf
				
				//o valor da tag xLgr deve possuir mais de um caracter 
				If Len( aDest[1] ) < 2
					aDest[1] := "LOGRADOURO: " + aDest[1]
				Else
					aDest[1] := PadR( aDest[1], 60 )
				EndIf
			
				If Empty(aDest[3]) .OR. aDest[3] == "0"
					aDest[3] := "SN"
				EndIf
	
				//tag <cPais> e <xPais>
				If Empty( SA1->A1_PAIS )
					cCPais := "1058"
					cXPais := "BRASIL"
				Else
					cCPais := Alltrim( Posicione("SYA", 1, xFilial("SYA") + SA1->A1_PAIS, "YA_SISEXP") )
					cCPais := Iif( Empty(cCPais), "1058", cCPais)
					
					cXPais := AllTrim( Posicione("SYA", 1, xFilial( "SYA" ) + SA1->A1_PAIS, "YA_DESCR") )
					cXPais := Iif( Empty(cXPais), "BRASIL", cXPais )
				EndIf
	
				//tag <fone>
				cFone := IIF( aFone[1] > 0, Left(cValToChar(aFone[1]) ,3), "" ) // C๓digo do Pais
				cFone += IIF( aFone[2] > 0, Left(cValToChar(aFone[2]) ,3), "" ) // C๓digo da มrea
				cFone += IIF( aFone[3] > 0, Left(cValToChar(aFone[3]) ,9), "" ) // C๓digo do Telefone
	
				cXMLAux += "<enderDest>"
				cXMLAux += 	"<xLgr>" + AllTrim( aDest[1] ) + "</xLgr>"
				cXMLAux += 	"<nro>" + AllTrim( aDest[3] ) + "</nro>"
				cXMLAux += 	"<xBairro>" + AllTrim(SA1->A1_BAIRRO) + "</xBairro>"
				cXMLAux += 	"<cMun>" + LjCodIBGE(SA1->A1_EST, SA1->A1_COD_MUN) + "</cMun>"
				cXMLAux += 	"<xMun>" + AllTrim(SA1->A1_MUN) + "</xMun>"
				cXMLAux += 	"<UF>" + AllTrim(SA1->A1_EST) + "</UF>"
				If !Empty(SA1->A1_CEP)
					cXMLAux += "<CEP>" + AllTrim(SA1->A1_CEP) + "</CEP>"
				EndIf
				cXMLAux += 	"<cPais>" + cCPais + "</cPais>"
				cXMLAux += 	"<xPais>" + cXPais + "</xPais>"
				If !Empty(cFone)
					cXMLAux +=	"<fone>" + Alltrim(cFone) + "</fone>"
				EndIf
				cXMLAux += "</enderDest>"
			EndIf
	
			//No caso de NFC-e informar indIEDest=9(Nao Contribuinte) e nao informar a tag <IE> do destinatario
			cXMLAux += 	"<indIEDest>9</indIEDest>"
	        
			If !Empty( SA1->A1_EMAIL )
				//-- TBC Limite 60 caracteres NFC-e					   
				cXMLAux += "<email>" + Left( AllTrim( SA1->A1_EMAIL ),60) + "</email>"
			EndIf
	
			cXMLAux += "</dest>"

            //sobrescrevendo tag no xml original
            nPosAux := AT('<dest>', cXmlRet)
            nPosAux2 := AT('</dest>', cXmlRet, nPosAux)

            //Conout("LJ7111 - Antes: " + SubStr(cXmlRet,nPosAux, (nPosAux2+len('</dest>')-nPosAux) )  )
            //Conout("LJ7111 - Depois: " + cXMLAux )

            cXmlRet := SubStr(cXmlRet,1,nPosAux-1) + cXMLAux + SubStr(cXmlRet,nPosAux2+len('</dest>'))

        endif
    endif

	//PABLO - 31/05: tratamento Rejei็ใo 441: Descri็ใo do pagamento obrigat๓ria para meio de pagamento 99- outros
	nPosAux := AT('99</tPag>', cXmlRet)
    If lAju441 .and. nPosAux > 0 
		nPosAux2 := AT('</detPag>', cXmlRet, nPosAux)
		While nPosAux > 0
			if AT('<xPag>', cXmlRet, nPosAux) <= 0 .OR. AT('<xPag>', cXmlRet, nPosAux) > nPosAux2
				//adiciona a descri็ใo do meio de pagamento utilizado 
				cXmlRet := SubStr(cXmlRet,1,nPosAux+len('99</tPag>')-1) + "<xPag>PAGAMENTO POSTO INTELIGENTE</xPag>" + SubStr(cXmlRet,nPosAux+len('99</tPag>'))
			endif
			nPosAux := AT('99</tPag>', cXmlRet, nPosAux+len('99</tPag>') )
		Enddo
	EndIf

	//Reescreve a tag <infNFeSupl> - bloco "ZX - Informa็๕es Suplementares da Nota Fiscal", quando houver alter็ใo no XML
	//ERRO: Digest Value (digVal): 397 Rejeicao: Parametro do QR-Code divergente da Nota Fiscal Param:6
	If cBkpXml <> cXmlRet
		//remove a tag <infNFeSupl>...</infNFeSupl> do XML
		nPosAux  := AT('<infNFeSupl>', cXmlRet)
		nPosAux2 := AT('</infNFeSupl>', cXmlRet, nPosAux)
		cXmlRet  := SubStr(cXmlRet,1,nPosAux-1) + SubStr(cXmlRet,nPosAux2+len('</infNFeSupl>'))

		//chama fun็ใo que alimenta o bloco "ZX"
		//cXMLSupl := StaticCall(LOJNFCE,LjNFCeSupl,cXmlRet)
		cXMLSupl := &("StaticCall(LOJNFCE,LjNFCeSupl,cXmlRet)")

		//adiciona retorno ao final do XML (antes do </NFe>)
		nPosAux := AT('</infNFe>', cXmlRet)
		cXmlRet := SubStr(cXmlRet,1,nPosAux+len('</infNFe>')-1) + cXMLSupl + SubStr(cXmlRet,nPosAux+len('</infNFe>'))
	EndIf

	//altera็ใo da url NFCE MG
	if GetMv("MV_ESTADO") == 'MG'
		//producao
		nPosAux  := AT('https://nfce.fazenda.mg.gov.br/portalnfce/sistema/qrcode.xhtml?', cXmlRet)
		if nPosAux > 0
			cXmlRet := StrTran(cXmlRet, 'https://nfce.fazenda.mg.gov.br/portalnfce/sistema/qrcode.xhtml?', 'https://portalsped.fazenda.mg.gov.br/portalnfce/sistema/qrcode.xhtml?')
		endif
		nPosAux  := AT('http://nfce.fazenda.mg.gov.br/portalnfce', cXmlRet)
		if nPosAux > 0
			cXmlRet := StrTran(cXmlRet, 'http://nfce.fazenda.mg.gov.br/portalnfce', 'https://portalsped.fazenda.mg.gov.br/portalnfce')
		endif
		//homologacao
		nPosAux  := AT('https://nfce.fazenda.mg.gov.br/portalnfce/sistema/qrcode.xhtml?', cXmlRet)
		if nPosAux > 0
			cXmlRet := StrTran(cXmlRet, 'https://nfce.fazenda.mg.gov.br/portalnfce/sistema/qrcode.xhtml?', 'https://portalsped.fazenda.mg.gov.br/portalnfce/sistema/qrcode.xhtml?')
		endif
		nPosAux  := AT('http://hnfce.fazenda.mg.gov.br/portalnfce', cXmlRet)
		if nPosAux > 0
			cXmlRet := StrTran(cXmlRet, 'http://hnfce.fazenda.mg.gov.br/portalnfce', 'https://hportalsped.fazenda.mg.gov.br/portalnfce')
		endif
	endif

	//-- TBC-GO - Marajo: log do XML montado a ser enviado para SEFAZ
	LjGrvLog( SL1->L1_NUM, "PE LJ7111 - XML que sera transmitido para o SEFAZ " + cXmlRet )

Return cXmlRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  LjCodIBGE บ Autor	ณVarejo				 บ Data ณ  24/09/14   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Retorna o C๓digo do Munํcipio do IBGE			 		  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno	 ณcCodIBGE - C๓digo do Munํcipio perante o IBGE				  บฑฑ 
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ LOJNFCE		                                              บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function LjCodIBGE(cUF, cCodMun)

	Local cCodIBGE	:= ""	//c๓digo do municํpio do IBGE
	Local nPos		:= 0	//posi็ใo de um determinado elemento no array
	Local aUF		:= {}	//array com os c๓digos das UF

	Default cUF		:= ""
	Default cCodMun := ""

	If cUF <> "EX"
		Aadd( aUF, {"RO","11"} )
		Aadd( aUF, {"AC","12"} )
		Aadd( aUF, {"AM","13"} )
		Aadd( aUF, {"RR","14"} )
		Aadd( aUF, {"PA","15"} )
		Aadd( aUF, {"AP","16"} )
		Aadd( aUF, {"TO","17"} )
		Aadd( aUF, {"MA","21"} )
		Aadd( aUF, {"PI","22"} )
		Aadd( aUF, {"CE","23"} )
		Aadd( aUF, {"RN","24"} )
		Aadd( aUF, {"PB","25"} )
		Aadd( aUF, {"PE","26"} )
		Aadd( aUF, {"AL","27"} )
		Aadd( aUF, {"MG","31"} )
		Aadd( aUF, {"ES","32"} )
		Aadd( aUF, {"RJ","33"} )
		Aadd( aUF, {"SP","35"} )
		Aadd( aUF, {"PR","41"} )
		Aadd( aUF, {"SC","42"} )
		Aadd( aUF, {"RS","43"} )
		Aadd( aUF, {"MS","50"} )
		Aadd( aUF, {"MT","51"} )
		Aadd( aUF, {"GO","52"} )
		Aadd( aUF, {"DF","53"} )
		Aadd( aUF, {"SE","28"} )
		Aadd( aUF, {"BA","29"} )
	
		nPos := aScan( aUF, {|x| x[1] == cUF} )
		If nPos > 0
			cCodIBGE := aUF[nPos][2] + AllTrim(cCodMun)
		EndIf
	Else
		cCodIBGE := "99" + "99999"
	EndIf

Return cCodIBGE
