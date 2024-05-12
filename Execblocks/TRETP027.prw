#include 'protheus.ch'

/*/{Protheus.doc} M460FIM
Função chamada pelo P.E. M460FIM para prencher a tabela CD6 - Complemento de Combustíveis

@author Totvs TBC
@since 02/10/2013
@version 1.0
@return Nulo

@type function
/*/

User Function TRETP027()

Local aArea		 	:= GetArea()
Local aAreaSD2	 	:= SD2->(GetArea())
Local cMV_COMBUS 	:= AllTrim(SuperGetMv("MV_COMBUS",.T.,""))
Local cCodAnp		:= ""
Local cMVEstado		:= GetMv("MV_ESTADO")
Local lTSefDev := SuperGetMV("MV_XTSFDEV",,.T.)//transmite automatico nota devolução para sefaz?

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return
EndIf

	SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	SD2->(DbGoTop())
	
	If SD2->(DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA))
	
		While SD2->(!Eof()) .and. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == (xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
			
			If (AllTrim(SD2->D2_GRUPO) $ cMV_COMBUS)
				
				//-- Consultar tabela de código ANP
				cCodAnp := IIF(SB1->(FieldPos("B1_CODSIMP"))>0,Posicione("SB1",1,xFilial("SB1")+(SD2->D2_COD),"B1_CODSIMP"),"")
				cCodAnp := IIF(!Empty(cCodAnp),cCodAnp,Posicione("SB5",1,xFilial("SB5")+(SD2->D2_COD),"B5_CODANP")) //B5_FILIAL+B5_COD
				
				Reclock("CD6",.T.)
					CD6->CD6_FILIAL	:= xFilial("CD6")
					CD6->CD6_TPMOV 	:= "S"
					CD6->CD6_DOC   	:= SF2->F2_DOC
					CD6->CD6_SERIE	:= SF2->F2_SERIE
					CD6->CD6_ESPEC 	:= SF2->F2_ESPECIE
					CD6->CD6_CLIFOR	:= SF2->F2_CLIENTE
					CD6->CD6_LOJA	:= SF2->F2_LOJA
					CD6->CD6_ITEM	:= SD2->D2_ITEM
					CD6->CD6_COD	:= SD2->D2_COD
					CD6->CD6_TEMP  	:= 25 //Temperatura em Celsius
					CD6->CD6_VOLUME	:= SD2->D2_QUANT
					CD6->CD6_CODANP	:= cCodAnp
					If CD6->(FieldPos("CD6_DESANP")) > 0 //-- Descrição do produto-ANP (Utilizado na geração da tag <descANP>)
						CD6->CD6_DESANP := Posicione("SZO",1,xFilial("SZO")+cCodAnp,"ZO_DESCRI") //ZO_FILIAL+ZO_CODCOMB
					EndIf
					CD6->CD6_UFCONS	:= cMVEstado
					CD6->CD6_BCCIDE := 0 //base da CIDE (IMPOSTO)
					CD6->CD6_VALIQ  := 0
					CD6->CD6_VCIDE  := 0
					CD6->CD6_PBRUTO := Iif(Empty(SD2->D2_PESO),1,SD2->D2_PESO)
					CD6->CD6_PLIQUI := Iif(Empty(SD2->D2_PESO),1,SD2->D2_PESO)
					CD6->CD6_QTAMB  := SD2->D2_QUANT
					CD6->CD6_QTDE  	:= SD2->D2_QUANT
					CD6->CD6_HORA	:= Iif(Empty(SF2->F2_HORA),Time(),SF2->F2_HORA)
					CD6->CD6_SEFAZ  := Iif(Empty(SF2->F2_CHVNFE),"0",SF2->F2_CHVNFE)

					//MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
					if CD6->(ColumnPos("CD6_PBIO")) > 0
						if !empty(Posicione("MHZ",3,xFilial("MHZ")+SD2->D2_COD+SD2->D2_LOCAL,"MHZ_CODTAN"))
							CD6->CD6_INDIMP := MHZ->MHZ_INDIMP
							CD6->CD6_UFORIG := MHZ->MHZ_UFORIG
							CD6->CD6_PORIG  := MHZ->MHZ_PORIG
							CD6->CD6_PBIO 	:= MHZ->MHZ_PBIO
						endif
					endif

				CD6->(MsUnlock())
			EndIf
			
			SD2->(DbSkip())
		EndDo
	EndIf

	If lTSefDev .AND. IsInCallStack("LOJA720") //Pedido incluido pela rotina de Troca/Devolução

		//transmite a NF de saída
		MsgRun("Aguarde, transmitindo a nota "+AllTrim(SF2->F2_DOC)+"/"+AllTrim(SF2->F2_SERIE)+"...",,{|| TransNF()})

		//abre o monitor de notas para verificar status de autorização da NF de saída
		SpedNFe6Mnt(SF2->F2_SERIE, SF2->F2_DOC, SF2->F2_DOC, .T.)
		
	EndIf

RestArea(aAreaSD2)
RestArea(aArea)

Return

//
// Transmite NFe de devolução (considera que esta posicionado na SF2)
//
Static Function TransNF()

	Local cRetorno		:= ""	//mensagem de retorno
	Local cIDEnt		:= ""
	Local cAmbiente		:= ""
	Local cModalidade	:= ""
	Local cVersao		:= ""
	Local lRetorno		:= .F.
	Local lEnd			:= .F.
	Local aArea			:= GetArea()
	Local aSF2aArea		:= SF2->( GetArea() )
	Local lAux  		:= .T.

	Private bFiltraBrw := {||}	//usado por compatibilidade por causa do fonte SPEDNFE.PRX

	MV_PAR01 := SF2->F2_SERIE
	MV_PAR02 := SF2->F2_DOC
	MV_PAR03 := SF2->F2_DOC

	//---------------------------
	// Obtem o codigo da entidade
	//---------------------------
	If Empty(SF2->F2_PDV)
		cIdEnt := RetIdEnti()
	Else // Advindo do TOTVS PDV
		If FindFunction("LjTSSIDEnt")
			cIdEnt := LjTSSIDEnt(IIF(SF2->F2_ESPECIE=="SPED","55","65"))
		Else
			//cIdEnt := StaticCall(LOJNFCE,LjTSSIDEnt,IIF(SF2->F2_ESPECIE=="SPED","55","65"))
			cIdEnt := &("StaticCall(LOJNFCE,LjTSSIDEnt,'"+IIF(SF2->F2_ESPECIE=="SPED","55","65")+"')")
		EndIf
	EndIf
	
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
			//Conout( "[IDENT: " + cIDEnt+"] - Iniciando transmissao NF-e de entrada! - " + Time() )

			cRetorno := SpedNFeTrf(	"SF2"	, SF2->F2_SERIE, SF2->F2_DOC , SF2->F2_DOC ,;
									cIDEnt	, cAmbiente	   , cModalidade , cVersao	   ,;
									@lEnd	, .F.		   , .F. )

			lRetorno := .T.

			//Conout( "[IDENT: " + cIDEnt+"] - Transmissao da NF-e de entrada finalizada! - " + Time() )
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
	RestArea(aSF2aArea)
	RestArea(aArea)

Return
