#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

Static lLogAbast := SuperGetMv("TP_LOGCABS",,.T.) //log conout
Static lLogAbAuto := SuperGetMv("TP_LOGABAU",,.F.) //log na pasta autocom

/*/{Protheus.doc} TRETE001
Biblioteca para comunicação com a concentradora de abastecimentos.

@author Wellington Gonçalves
@since 16/05/2014
@version 1.0
@return ${return}, ${return_description}

@param cCodConcentradora, characters, Código da concentradora
@param cID, characters, ID do método
@param aString, array, Array com String de envio
@type function
/*/
User Function TRETE001(cCodConcentradora,cID,aString)

	Local xStrRet // variável que irá receber o retorno das funções de comunicação com a concentradora
	Local cIP		:= ""
	Local nPorta	:= 0
	Local cModelo	:= ""
	Local cCodigo	:= ""
	Local cStatus	:= ""
	Local cDtIni	:= DTOC(Date())
	Local cHrIni	:= Time()

	if lLogAbast
		Conout("")
		Conout("********* INICIO DA COMUNICACAO COM A CONCENTRADORA: "+cCodConcentradora+" *********")
		Conout(" - DATA INI: " + cDtIni)
		Conout(" - HORA INI: " + cHrIni)
		Conout("")
	endif

	MHX->(DbSetOrder(1)) // MHX_FILIAL+MHX_CODCON
	if MHX->(DbSeek(xFilial("MHX") + cCodConcentradora))

		if lLogAbast
			Conout(" - CONCENTRADORA: " + MHX->MHX_CODCON)
			Conout(" - MODELO: " + MHX->MHX_CODFAB + " - " + MHX->MHX_MODELO)
		endif

		cIP		:= AllTrim(MHX->MHX_IP)
		nPorta	:= MHX->MHX_PORTA
		nPorta	:= iif(nPorta <= 0,9999,nPorta)
		cModelo	:= MHX->MHX_CODFAB
		cCodigo	:= MHX->MHX_CODCON
		cStatus	:= MHX->MHX_STATUS

		if cID == "1" // le abastecimento
			xStrRet := Abastecimentos(cStatus,cCodigo,cModelo,cIP,nPorta,aString)
		elseif cID == "2" // pula para próximo abastecimento
			xStrRet := ProximoAbast(cStatus,cModelo,cIP,nPorta)
		elseif cID == "3"
			xStrRet := AtuPreco(cStatus,cModelo,cIP,nPorta,aString)
		elseif cID == "4"
			xStrRet := GrvIdentfid(cStatus,cModelo,cIP,nPorta,aString)
		elseif cID == "5"
			xStrRet := ApagaIdentfid(cStatus,cModelo,cIP,nPorta,aString)
		elseif cID == "6"
			xStrRet := LimpaIdentfid(cStatus,cModelo,cIP,nPorta)
		elseif cID == "7"
			xStrRet := Encerrante(cStatus,cModelo,cIP,nPorta,aString)
		elseif cId == "8"
			xStrRet := MudaStatus(cStatus,cModelo,cIP,nPorta,aString)
		elseif cId == "9"
			xStrRet := LerStatus(cStatus,cCodigo,cModelo,cIP,nPorta)
		elseif cId == "10"
			xStrRet := LiberaValor(cStatus,cModelo,cIP,nPorta,aString)
		elseif lLogAbast
			Conout(" >> ID INVALIDO")
		endif

	elseif lLogAbast
		Conout(" >> CONCENTRADORA INVALIDA")
	endif

	if lLogAbast
		Conout("")
		Conout("*********** FIM DA COMUNICACAO COM A CONCENTRADORA: "+cCodConcentradora+" **********")
		Conout(" - DATA INI: " + cDtIni)
		Conout(" - HORA INI: " + cHrIni)
		Conout(" - DATA FIM: " + DTOC(Date()))
		Conout(" - HORA FIM: " + Time())

		Conout("")
		Conout("")
	endif

Return(xStrRet)


/*/{Protheus.doc} Abastecimentos
Função para leitura de abastecimentos da concentradora de combustível.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, Status
@param cConcent, characters, Cógido da concentradora
@param cModelo, characters, Modelo da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@param aString, array, Array: Quantidade de leitura de abastecimentos
@type function
/*/
Static Function Abastecimentos(cStatus,cConcent,cModelo,cIP,nPorta,aString)

	Local cDataLimite	:= aString[1]
	Local cHoraLimite	:= aString[2]
	Local lCBCNew 		:= SuperGETMV('MV_XCBCNEW',,.T.)

	if cStatus == "1" // Ativado
		if lLogAbast		
			Conout(" - STATUS: ATIVADO")
			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))
		endif
		if cModelo == "01" .OR. cModelo == "02"  // se a concentradora for CBC-05 ou Horustech/CBC-06
			if !lCBCNew
				AbastCBC(cConcent,cModelo,cIP,nPorta)
			else
				AbCBCNew(cConcent,cModelo,cIP,nPorta)
			endif
		elseif cModelo == "03" // se a concentradora for Fusion
			if MHX->( FieldPos("MHX_XLEITU") ) > 0
				AbFusionNew(cConcent,cIp,nPorta) // nova modelagem para leitura de abastecimentos
			else
				AbastFusion(cConcent,cIp,nPorta,cDataLimite,cHoraLimite)
			endif
		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return()


/*/{Protheus.doc} ProximoAbast
Função que pula para o próximo abastecimento da concentradora CBC.
String de envio: (&I)
String de retorno: Booleano

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, Status
@param cModelo, characters, dModelo da concentradora	escricao
@param cIP, characters, IP
@param nPorta, numeric, Porta
@type function
/*/
Static Function ProximoAbast(cStatus,cModelo,cIP,nPorta)

	Local cStrEnvio	:= "(&I)"
	Local cRet		:= ""
	Local lConect	:= .F.

	if cStatus == "1" // Ativado
		if lLogAbast
			Conout(" - STATUS: ATIVADO")
		endif
		Sleep(2000)

		if lLogAbast
			Conout("")

			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))

			Conout(" >> COMANDO " + cStrEnvio + " - PROXIMO ABASTECIMENTO")
		endif
		// chamo a função que faz conexão via socket
		lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

		if lLogAbast
			Conout("")
		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif
	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(lConect)


/*/{Protheus.doc} AtuPreco

Função que atualiza o preço do bico na concentradora.
String de envio: (&UBBN0PPPPKK)
&U ------------------ Cabeçalho;
BB ------------------ Numero logico do bico;
N ------------------- Nível de preço, (0: a vista; 1: a prazo)
PPPP ---------------- Preço (3 casas decimais);
KK ------------------ SheckSum;
String de retorno:
		- (UBB) : Comando aceito;
		- (U?t) : Timeout da bomba;
		- (U?b) : Código de bico inválido;
		- (U?r) : Erro de resposta da bomba;

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, descricao
@param cModelo, characters, Modelo da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@param aString, array, Array com String de envio sendo a seguintes posições:
			- Número lógico do bico
			- Lado da bomba
			- Preço
@type function
/*/
Static Function AtuPreco(cStatus,cModelo,cIP,nPorta,aString)

	Local cStrEnvio	:= ""
	Local cRet 		:= ""
	Local cCheckSum	:= ""
	Local lConect	:= .F.
	Local nTamLado	:= TamSX3("MIC_LADO")[1]
	Local aConfig	:= {}
	Local aPreco	:= ""
	Local cPreco	:= ""
	Local cTipoPrc	:= "0" //"0" dinheiro, "1" debito e "2" crédito
	Local cNumLogic	:= ""
	Local nPrcInt	:= 0
	Local nPrcFloat	:= 0
	Local lRet		:= .F.
	Local nPosGrade	:= 0
	Local nPosRC	:= 0
	Local lNivCBC	:= SuperGETMV('MV_XNIVCBC',,.F.)
	Local nDecPrc	:= 0
	Local lBicoAtivo := .F.

	if cStatus == "1" // Ativado
		if lLogAbast
			Conout(" - STATUS: ATIVADO")
			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))
		endif
		if cModelo == "01" .OR. cModelo == "02"  // se a concentradora for CBC-05 ou Horustech/CBC-06

			cNumLogic	:= aString[1]

			// posiciono na tabela de bicos
			if MIC->(FieldPos("MIC_XDECPR")) > 0
				MIC->(DbOrderNickName("MIC_001")) //MIC_FILIAL+MIC_XCONCE+MIC_LADO+MIC_NLOGIC
				if MIC->(DbSeek(xFilial("MIC") + MHX->MHX_CODCON + Space(TamSX3("MIC_LADO")[1]) + cNumLogic)) 
					//.AND. MIC->MIC_STATUS == "1" // se o bico estiver ativo

					lBicoAtivo := .F.
					While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_XCONCE+MIC->MIC_LADO+Alltrim(MIC->MIC_NLOGIC) == xFilial("MIC") + MHX->MHX_CODCON + Space(TamSX3("MIC_LADO")[1]) + cNumLogic
						if  ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataBase) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataBase))
							lBicoAtivo := .T.
							EXIT
						endif
						MIC->(DBSkip())
					EndDO

					if lBicoAtivo
						nDecPrc := MIC->MIC_XDECPR // casas decimais da quantidade
					endif
				endif
			endif
			
			//Tratamento para casas decimais, com origem no cadastro da concentradora
			if nDecPrc == 0
				nDecPrc	:= MHX->MHX_DECPRC // casas decimais do preço unitário
				if nDecPrc == 0
					nDecPrc := 3
				endif
			endif

			nPrcInt 	:= Int(aString[3])
			nPrcFloat	:= aString[3] - nPrcInt // parte decimal do preço
			cPreco 		:= cValToChar(nPrcInt) + PADR(SubStr(cValToChar(nPrcFloat),3,3),nDecPrc,"0")
			if nDecPrc < 3
				cPreco := Replicate("0",3-nDecPrc) + cPreco
			endif

			// verifica se esta habilitado preço por nível
			If lNivCBC .and. Len(aString)>3
				cTipoPrc	:= aString[4] //"0" dinheiro, "1" debito e "2" crédito
			EndIf

			// monto a string de envio
			cStrEnvio := "&U" + cNumLogic + cTipoPrc + "0" + cPreco

			// chamo função que calcula o CheckSum
			cCheckSum := CheckSum(cStrEnvio)

			// monto a string de envio
			cStrEnvio := "(" + cStrEnvio + cCheckSum + ")"

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - ATUALIZACAO DE PRECO")
			endif

			// chamo a função que faz conexão via socket
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			// se o retorno for NIL ou vazio, a conexão não foi realizada
			if !lConect .OR. ValType(cRet) <> "C" .OR. Empty(cRet)
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			else

				// retiro os parêntesis do retorno
				cRet := StrTran(cRet,"(","")
				cRet := StrTran(cRet,")","")

				if AllTrim(cRet) == "U" + cNumLogic
					lRet := .T.
					if lLogAbast
						Conout(" >> PRECO ENVIADO COM SUCESSO")
					endif
				elseif AllTrim(cRet) == "U?t"
					if lLogAbast
						Conout(" >> ERRO (U?t) - TIMEOUT DA BOMBA")
					endif
				elseif AllTrim(cRet) == "U?b"
					if lLogAbast
						Conout(" >> ERRO (U?b) - CODIGO DO BICO INVALIDO")
					endif
				elseif AllTrim(cRet) == "U?r"
					if lLogAbast
						Conout(" >> ERRO (U?r) - ERRO DE RESPOSTA DA BOMBA")
					endif
				elseif Empty(cRet)
					if lLogAbast
						Conout(" >> ERRO - NAO FOI POSSIVEL COMUNICAR COM A CONCENTRADORA")
					endif
				else
					if lLogAbast
						Conout(" >> ERRO - CODIGO DE RETORNO INVALIDO")
					endif
				endif

			endif

		elseif cModelo == "03" // se a concentradora for Fusion

			cNumLogic	:= aString[1]
			cLado 		:= aString[2]
			nPrcInt 	:= Int(aString[3])
			nPrcFloat	:= aString[3] - nPrcInt // parte decimal do preço
			// cPreco 		:= cValToChar(nPrcInt) + PADR(SubStr(cValToChar(nPrcFloat),3,3),3,"0")
			cPreco 		:= cValToChar(aString[3])

			// monto a string para pegar a configuração da bomba
			cStrEnvio := "00034|5|2||POST|REQ_FCRT_PUMPS_CONFIG||||^"
			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - ATUALIZACAO DE PRECO")
			endif

			// envio comando para fusion
			lConect := U_XSocketP(cIp,nPorta,cStrEnvio,@cRet)

			// se a conexão foi realizada com sucesso
			if lConect

				// transformo a string de retorno em array
				aConfig := StrToKarr(cRet,"|")

				// valido se o array tem pelo menos uma posição para não dar erro
				if Len(aConfig) > 0

					// verifico qual a grade de preco (ID referente ao produto) está vinculado a este bico
					cStrGrd		:= "P" + Padl(cLado,nTamLado,"0") + "H" + cValToChar(Val(cNumLogic)) + "GRADE="
					nPosGrade 	:= aScan(aConfig,{|x| SubStr(AllTrim(x),1,Len(cStrGrd)) == cStrGrd})

					// existir a TAG com a grade
					if nPosGrade > 0

						cGrade := StrTran(aConfig[nPosGrade],cStrGrd,"")

						// monto a string para enviar o preço para a fusion
						cStrEnvio := "2||POST|REQ_PRICES_SET_NEW_PRICE_CHANGE|||QTY=1|G01NR=" + cGrade + "|G01LV=1|G01PR=" + cPreco + "|^"
						cStrEnvio := PADL(cValToChar(Len(cStrEnvio)),5,"0") + "|5|" + cStrEnvio

						if lLogAbast
							Conout(" >> COMANDO " + cStrEnvio + " - ATUALIZACAO DE PRECO")
						endif

						// envio comando para fusion
						lConect := U_XSocketP(cIp,nPorta,cStrEnvio,@cRet)

						// se a conexão foi realizada com sucesso
						if lConect

							// transformo a string de retorno em array
							aPreco := StrToKarr(cRet,"|")

							// verifico se o retorno contém a TAG RC=, caso contenha verifico se está OK
							nPosRC := aScan(aPreco,{|x| SubStr(AllTrim(x),1,3) == "RC="})

							if nPosRC > 0

								if StrTran(aPreco[nPosRC],"RC=","") == "OK"
									if lLogAbast
										Conout(" >> PRECO ENVIADO COM SUCESSO")
									endif
									lRet := .T.
								endif

							endif

						elseif lLogAbast
							Conout(" >> CONEXAO NAO REALIZADA")
						endif

					endif

				endif

			elseif lLogAbast
				Conout(" >> CONEXAO NAO REALIZADA")
			endif

		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif
	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(lRet)

/*/{Protheus.doc} GrvIdentfid
Função que grava o código Identfid do vendedor na memória da concentradora.
String de envio: Comando: (?FCCGT[16]AAAAaaaaBBBBbbbbKK)
&F ------------------ Cabeçalho;
CC ------------------ Controle;
G ------------------- Comando para gravar;
T[16] --------------- Código do identificador;
AAAA ---------------- Turno inicial A; (hhmm)
aaaa ---------------- Turno final A; (hhmm)
BBBB ---------------- Turno inicial B; (hhmm)
bbbb ---------------- Turno final B; (hhmm)
KK ------------------ CheckSum;
String de retorno: Comando: (FGP[6]M[6]T[16]AAAAaaaaBBBBbbbbCCKK)
F ------------------- Cabeçalho;
G ------------------- Comando para gravar;
P[6] ---------------- Posição onde foi armazenado;
M[6] ---------------- Quantidade de identificadores na memória;
T[16] --------------- Código do identificador;
AAAA ---------------- Turno inicial A; (hhmm)
aaaa ---------------- Turno final A; (hhmm)
BBBB ---------------- Turno inicial B; (hhmm)
bbbb ---------------- Turno final B; (hhmm)
CC ------------------ Controle;
KK ------------------ CheckSum;

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, descricao
Parâmetros:
1 - Modelo da concentradora
2 - IP
3 - Porta
4 - Array com String de envio sendo a seguintes posições:
		- Codigo do cartao
		- Data inicial do turno 1
		- Data final do turno 1
		- Data inicial do turno 2
		- Data final do turno 2
@type function
/*/
Static Function GrvIdentfid(cStatus,cModelo,cIP,nPorta,aString)

	Local cStrEnvio	:= ""
	Local cControle	:= "27" //27=Dinheiro;28=Débito;29=Credito
	Local cRet 		:= ""
	Local cCheckSum	:= ""
	Local lConect	:= .F.
	Local lNivCBC	:= SuperGETMV('MV_XNIVCBC',,.F.)

	if cStatus == "1" // Ativado

		if lLogAbast
			Conout(" - STATUS: ATIVADO")
			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))
		endif

		// verifica se esta habilitado preço por nível
		If lNivCBC .and. U68->( FieldPos("U68_TIPPRC") ) > 0 .and. Len(aString)>5
			cControle := aString[6]
		EndIf

		// monto a string de envio
		cStrEnvio := "?F" + cControle + "G" + aString[1] + aString[2] + aString[3] + aString[4] + aString[5]

		// chamo função que calcula o CheckSum
		cCheckSum := CheckSum(cStrEnvio)

		// concateno a string de envio com o checksum
		cStrEnvio := "(" + cStrEnvio + cCheckSum + ")"

		if cModelo == "01" // CBC-05
			if lLogAbast
				Conout(" >> COMANDO NAO DISPONIVEL PARA CBC-05")
			endif
		elseif cModelo == "03" // FUSION
			if lLogAbast
				Conout(" >> COMANDO NAO DISPONIVEL PARA A FUSION")
			endif
		else

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - GRAVACAO DO IDENTFID")
			endif

			// chamo a função que faz conexão via socket
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			If !lConect .OR. ValType(cRet) <> "C" .OR. Empty(cRet)
				cRet := ""
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			else

				cRet := StrTran(cRet,"(0)","")
				cRet := StrTran(cRet,"(","")
				cRet := StrTran(cRet,")","")

			endif

		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif
	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(cRet)


/*/{Protheus.doc} ApagaIdentfid
Função que apaga o código Identfid do vendedor na memória da concentradora.
String de envio: Comando: (?FXXATTTTTTTTTTTTTTTT00RRRRRR00000000KK)
&F ------------------ Cabeçalho;
XX ------------------ Caracteres de controle (padrão “FF”);
A ------------------- Comando para apagar;
T[16] --------------- Código do identificador;
00 ------------------ Campo fixo;
R[6] ---------------- Posição do registro;
00000000 ------------ Campo fixo;
KK ------------------ CheckSum;
String de retorno: Comando: (FAXXXXXXSSSSSSCCCCCCCCCCCCCCCCIIIIIIIIFFFFFFFFXXKK)
F ------------------- Cabeçalho;
A ------------------- Comando para apagar;
X[6] ---------------- Número do registro apagado, 000000 não apagado;
S[6] ---------------- Número de registro requerido;
C[16] --------------- Cód identfid no registro requerido = 0000000000000000 reg limpo;
I[8] ---------------- Turno A (hhmmhhmm)
F[8] ---------------- Turno B (hhmmhhmm)
XX ------------------ Caracteres de controle;
KK ------------------ CheckSum;

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, descricao
Parâmetros:
1 - Modelo da concentradora
2 - IP
3 - Porta
4 - Array com String de envio sendo a seguintes posições:
		- Codigo do cartao
		- Posicao de memoria do cartao na concentradora
@type function
/*/
Static Function ApagaIdentfid(cStatus,cModelo,cIP,nPorta,aString)

	Local cStrEnvio	:= ""
	Local cControle	:= "FF"
	Local cRet 		:= ""
	Local cCheckSum	:= ""
	Local lConect	:= .F.

	if cStatus == "1" // Ativado

		if lLogAbast
			Conout(" - STATUS: ATIVADO")
			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))
		endif

		// monto a string de envio
		cStrEnvio := "?F" + cControle + "A" + aString[1] + "00" + aString[2] + "00000000"

		// chamo função que calcula o CheckSum
		cCheckSum := CheckSum(cStrEnvio)

		// concateno a string de envio com o checksum
		cStrEnvio := "(" + cStrEnvio + cCheckSum + ")"

		if cModelo == "01" // CBC-05
			if lLogAbast
				Conout(" >> COMANDO NAO DISPONIVEL PARA CBC-05")
			endif
		elseif cModelo == "03" // FUSION
			if lLogAbast
				Conout(" >> COMANDO NAO DISPONIVEL PARA A FUSION")
			endif
		else // Horustech/CBC-06

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - APAGAR IDENTFID DA CONCENTRADORA")
			endif

			// chamo a função que faz conexão via socket
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			If !lConect .OR. ValType(cRet) <> "C" .OR. Empty(cRet)
				cRet := ""
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			Else

				cRet := StrTran(cRet,"(0)","")
				cRet := StrTran(cRet,"(","")
				cRet := StrTran(cRet,")","")

			EndIf

		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(cRet)


/*/{Protheus.doc} LimpaIdentfid
Função que limpa todos os códigos Identfid do vendedor da memória da concentradora.
String de envio: Comando: (?F00L0000000000000000000000010000000032)
String de retorno: BOOLEANO

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, descricao
@param cModelo, characters, Modelo da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@type function
/*/
Static Function LimpaIdentfid(cStatus,cModelo,cIP,nPorta)

	Local cStrEnvio	:= "(?F00L0000000000000000000000010000000032)"
	Local cRet		:= ""
	Local lRet 		:= .F.
	Local lConect	:= .F.

	if cStatus == "1" // Ativado

		if lLogAbast
			Conout(" - STATUS: ATIVADO")
			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))
		endif

		if cModelo == "01" // CBC-05
			if lLogAbast
				Conout(" >> COMANDO NAO DISPONIVEL PARA CBC-05")
			endif
		elseif cModelo == "03" // FUSION
			if lLogAbast
				Conout(" >> COMANDO NAO DISPONIVEL PARA A FUSION")
			endif	
		else

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - LIMPAR TODOS OS IDENTFID'S DA CONCENTRADORA")
			endif

			// chamo a função que faz conexão via socket
			lConect := U_XSocketP(cIP,iif(nPorta <= 0,9999,nPorta),cStrEnvio,@cRet)

			If !lConect .OR. ValType(cRet) <> "C"
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			Else
				if lLogAbast
					Conout(" >> OPERACAO REALIZADA COM SUCESSO!")
				endif
				lRet := .T.
			EndIf

		Endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif
	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(lRet)


/*/{Protheus.doc} Encerrante
Função que le o encerrante do bico.

Para a concentradora CBC:
String de envio: (&TBBMKK)
&T ------------------ Cabeçalho;
BB ------------------ Número lógico do bico;
M ------------------- Modo leitura ($=Valor;L=Litros;N=Num Serie;U=PPL;P=Pont memoria);
KK ------------------ CheckSum;
String de retorno: (TMBBAAAAVVVVKK)
T ------------------- Cabeçalho;
M ------------------- Modo de leitura;
BB ------------------ Número lógico do bico;
AAAAVVVV ------------ Pode conter os seguintes significados de acordo com o modo:
		- AAAAVVVV:Valor do encerrante com 2 casas decimais;
		- AAAAVVVV: Numero de serie 8 digitos numéricos:
		- AAAA: se pedido PPL nível 2 (a prazo)
		- VVVV: se pedido PPL nível 1 (a vista)
		- AAAA: Número do ponteiro se comando P;
	- VVVV: Número do ponteiro se comando P;
KK ------------------ CheckSum;

Para a concentradora Fusion:
String de envio: REQ_PUMP_GET_TOTALS_ID_XXX
XXX - Número lógico da bomba, deverá ser passado como parâmetro o HO  do bico;
String de retorno: RES_PUMP_GET_TOTALS_ID_XXX
XXX - Número lógico da bomba;
HxTV - Encerrante em litros;
HxTM - Encerrante em dinheiro;

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, descricao
Parâmetros:
1 - Modelo da concentradora
2 - IP
3 - Porta
4 - Array com String de envio sendo a seguintes posições:
		- Número lógico do bico
		- Lado da bomba (para concentradora Fusion)
		- Modo de leitura
@type function
/*/
Static Function Encerrante(cStatus,cModelo,cIP,nPorta,aString)

	Local cStrEnvio	:= ""
	Local cRet 		:= ""
	Local nRet		:= 0
	Local cCheckSum	:= ""
	Local cNumLogic	:= ""
	Local cLado		:= ""
	Local cTipoEnc	:= ""
	Local nPosRS	:= 0
	Local nPosLt	:= 0
	Local lConect	:= .F.

	if cStatus == "1" // Ativado

		if lLogAbast
			Conout(" - STATUS: ATIVADO")
			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))
		endif

		if cModelo == "01" .OR. cModelo == "02"  // se a concentradora for CBC-05 ou Horustech/CBC-06

			cNumLogic 	:= AllTrim(aString[1]) // número lógico do bico
			cTipoEnc	:= aString[3] // tipo de leitura, valor ou volume

			// monto a string de envio
			cStrEnvio := "&T" + cNumLogic + cTipoEnc

			// chamo função que calcula o CheckSum
			cCheckSum := CheckSum(cStrEnvio)

			// concateno a string de envio com o checksum
			cStrEnvio := "(" + cStrEnvio + cCheckSum + ")"

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - LEITURA DE ENCERRANTE")
			endif

			// envio comando para CBC
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			If !lConect .OR. ValType(cRet) <> "C" .OR. Empty(cRet)
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			Else

				cRet := StrTran(cRet,"(0)","")
				cRet := StrTran(cRet,"(","")
				cRet := StrTran(cRet,")","")
				cRet := SubStr(cRet,5,8)
				nRet := Val( SubStr(cRet,1,6) + "." + SubStr(cRet,7,2) )

			EndIf

		elseif cModelo == "03" // se a concentradora for Fusion

			cNumLogic 	:= AllTrim(aString[1]) // número lógico do bico
			cLado		:= aString[2] // lado da bomba
			cTipoEnc	:= aString[3] // tipo de leitura, valor ou volume

			cStrEnvio := "2||POST|REQ_PUMP_GET_TOTALS_ID_" + PADL(cLado,3,"0") + "|||HO=" + PADL(cNumLogic,3,"0") + "|^"
			cStrEnvio := PADL(cValToChar(Len(cStrEnvio)),5,"0") + "|5|" + cStrEnvio

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - LEITURA DE ENCERRANTE")
			endif

			// envio comando para fusion
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			if lConect

				// transformo a string de retorno em array
				aEncerrante := StrToKarr(cRet,"|")

				if Len(aEncerrante) > 0

					if cTipoEnc == "$" // valor

						// verifico se o retorno tem a TAG com o encerrante em valor
						nPosRS	:= aScan(aEncerrante,{|x| SubStr(AllTrim(x),1,5) == "H1TM="})

						if nPosRS > 0
							nRet := Val(StrTran(aEncerrante[nPosRS],"H1TM=",""))
						endif

					elseif cTipoEnc == "L" // volume

						// verifico se o retorno tem a TAG com o encerrante em valor
						nPosLt	:= aScan(aEncerrante,{|x| SubStr(AllTrim(x),1,5) == "H1TV="})

						if nPosLt > 0
							nRet := Val(StrTran(aEncerrante[nPosLt],"H1TV=",""))
						endif

					endif

				endif

			elseif lLogAbast
				Conout(" >> CONEXAO NAO REALIZADA")
			endif

		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(nRet)

/*/{Protheus.doc} MudaStatus
Função que muda o status do bico.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, descricao
Parâmetros:
1 - Status da concentradora
2 - Modelo da concentradora
3 - IP
4 - Porta
5 - Array com String de envio sendo a seguintes posições:
		- Número lógico do bico
		- Lado da bomba (para concentradora Fusion)
		- Modo do bico
@type function
/*/
Static Function MudaStatus(cStatus,cModelo,cIP,nPorta,aString)

	Local cStrEnvio	:= ""
	Local cCheckSum	:= ""
	Local cModo		:= ""
	Local cNumLogic	:= ""
	Local lRet 		:= .F.
	Local cRet		:= ""
	Local lConect	:= .F.

	if cStatus == "1" // Ativado

		if lLogAbast
			Conout(" - STATUS: ATIVADO")
			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))
		endif

		if cModelo == "01" .OR. cModelo == "02"  // se a concentradora for CBC-05 ou Horustech/CBC-06

			cNumLogic := AllTrim(aString[1]) // retiro o espaço em branco, pois a CBC tem 2 caracteres no número lógico

			if aString[3] == "L" // comando para liberar o bico
				cModo := "L"
			elseif aString[3] == "B" // comando para bloquear o bico
				cModo := "B"
			elseif aString[3] == "P" // comando para parar o abastecimento que está em andamento
				cModo := "S"
			elseif aString[3] == "A" // comando para autorizar o bico
				cModo := "A"
			else
				cModo := ""
			endif

			// monto a string de envio
			cStrEnvio := "&M" + cNumLogic + cModo

			// chamo função que calcula o CheckSum
			cCheckSum := CheckSum(cStrEnvio)

			// concateno a string de envio com o checksum
			cStrEnvio := "(" + cStrEnvio + cCheckSum + ")"

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - MODO DO BICO")
			endif

			// chamo a função que faz conexão via socket
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			If !lConect .OR. ValType(cRet) <> "C" .OR. Empty(cRet)
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			Else

				cRet := StrTran(cRet,"(0)","")
				cRet := StrTran(cRet,"(","")
				cRet := StrTran(cRet,")","")

				if cRet == "M" + cNumLogic
					lRet := .T.
					if lLogAbast
						Conout(" >> MODO DO BICO ALTERADO COM SUCESSO")
					endif
				elseif cRet == "M?t"
					if lLogAbast
						Conout(" >> TIMEOUT DA BOMBA")
					endif
				elseif cRet == "M?b"
					if lLogAbast
						Conout(" >> NUMERO LOGICO INVALIDO")
					endif
				elseif cRet == "M?r"
					if lLogAbast
						Conout(" >> ERRO DE RESPOSTA DO BICO")
					endif
				endif

			EndIf

		elseif cModelo == "03" // se a concentradora for Fusion

			if aString[3] == "L" // comando para liberar o bico
				cModo := "REQ_PUMP_OPEN_ID_"
			elseif aString[3] == "B" // comando para bloquear o bico
				cModo := "REQ_PUMP_CLOSE_ID_"
			elseif aString[3] == "P" // comando para parar o abastecimento que está em andamento
				cModo := "REQ_PUMP_STOP_ID_"
			elseif aString[3] == "A" // comando para autorizar o bico
				cModo := "REQ_PUMP_AUTH_ID_" //"REQ_PUMP_DEAUTH_ID_"
			else
				cModo := ""
			endif

			cStrEnvio := "2||POST|" + cModo + PADL(aString[2],3,"0") + "||||^"
			cStrEnvio := PADL(cValToChar(Len(cStrEnvio)),5,"0") + "|5|" + cStrEnvio

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - MODO DO BICO")
			endif

			// envio comando para fusion
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			if lConect

				if Empty(cRet)
					lRet := .T.
					if lLogAbast
						Conout(" >> MODO DA BOMBA ALTERADO COM SUCESSO!")
					endif
				else
					if lLogAbast
						Conout(" >> NAO FOI POSSIVEL ALTERAR O MODO DA BOMBA")
					endif
				endif

			elseif lLogAbast
				Conout(" >> CONEXAO NAO REALIZADA")
			endif

		elseif lLogAbast
			Conout(" >> MODELO DA CONCENTRADORA INVALIDO")
		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(lRet)


/*/{Protheus.doc} LerStatus
Função que faz a leitura do status dos bicos.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, descricao
@param cConcent, characters, Codigo da concentradora
@param cModelo, characters, Modelo da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@type function
/*/
Static Function LerStatus(cStatus,cConcent,cModelo,cIP,nPorta)

	Local aRet := {}

	if lLogAbast
		Conout(" >> CONEXAO VIA SOCKET")
		Conout(" - IP: " + cIP )
		Conout(" - Porta: " + cValToChar(nPorta))
	endif

	if cStatus == "1" // Ativado

		if lLogAbast
			Conout(" - STATUS: ATIVADO")
		endif

		if cModelo == "01" .OR. cModelo == "02"  // se a concentradora for CBC-05 ou Horustech/CBC-06

			// chamo função que retorna o status dos bicos da CBC
			aRet := StatusCBC(cConcent,cIP,nPorta)

		elseif cModelo == "03" // se a concentradora for Fusion

			// chamo função que retorna o status dos bicos da Fusion
			aRet := StatusFusion(cConcent,cIP,nPorta)

		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(aRet)

/*/{Protheus.doc} LiberaValor
Função que libera o bico com pré-determinação de valor.
String de envio: (&PBB$$$$$$KK)
		- &P: Cabeçalho;
		- BB: Número lógico do bico;
		- $$$$$$: Valor do PRESET (0=Sem limite);
		- KK: Check;
String de retorno:
		- (PBB): Comando aceito;
		- (P?t): Timeout da bomba;
		- (P?b): Código de bico inválido;
		- (P?r): Erro de resposta da bomba;

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cStatus, characters, descricao
@param cModelo, characters, Modelo da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@param aString, array, Array com String de envio sendo a seguintes posições:
		- Número lógico do bico
		- Lado da bomba
		- Valor
@type function
/*/
Static Function LiberaValor(cStatus,cModelo,cIP,nPorta,aString)

	Local cStrEnvio		:= ""
	Local cRet 			:= ""
	Local lRet			:= .F.
	Local cCheckSum		:= ""
	Local cNumLogico	:= ""
	Local cLado			:= ""
	Local cValor		:= ""
	Local cValorInt		:= ""
	Local cValorFloat	:= ""

	if cStatus == "1" // Ativado

		if lLogAbast
			Conout(" - STATUS: ATIVADO")
			Conout(" >> CONEXAO VIA SOCKET")
			Conout(" - IP: " + cIP )
			Conout(" - Porta: " + cValToChar(nPorta))
		endif

		if cModelo == "01" .OR. cModelo == "02"  // se a concentradora for CBC-05 ou Horustech/CBC-06

			cNumLogico 	:= PADR(AllTrim(aString[1]),2)

			// se o valor é maior que zero, envio o comando de preset
			if aString[3] > 0

				cValorInt	:= STRZERO(INT(aString[3]),4)
				cValorFloat	:= STRZERO(INT( (aString[3] - INT(aString[3])) * 100),2)
				cStrEnvio 	:= "&P" + cNumLogico + cValorInt + cValorFloat

			else // senão, envio o comando para liberar apenas o próximo abastecimento
				cStrEnvio := "&M" + cNumLogico + "A"
			endif

			// chamo função que calcula o CheckSum
			cCheckSum := CheckSum(cStrEnvio)

			// concateno a string de envio com o checksum
			cStrEnvio := "(" + cStrEnvio + cCheckSum + ")"

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - LIBERACAO DE BICO (PRESET)")
			endif

			// chamo a função que faz conexão via socket
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			If !lConect .OR. ValType(cRet) <> "C" .OR. Empty(cRet)
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			Else

				cRet := StrTran(cRet,"(0)","")
				cRet := StrTran(cRet,"(","")
				cRet := StrTran(cRet,")","")

				if aString[3] > 0 // valor maior que zero

					if AllTrim(cRet) == ("P" + cNumLogico)
						lRet := .T.
						Conout(" >> PRESET ENVIADO COM SUCESSO!")
					else
						Conout(" >> NAO FOI POSSIVEL ENVIAR O PRESET PARA O BICO!")
					endif

				else

					if cRet == "M" + cNumLogico
						lRet := .T.
						if lLogAbast
							Conout(" >> MODO DO BICO ALTERADO COM SUCESSO")
						endif
					elseif lLogAbast
						Conout(" >> NAO FOI POSSIVEL ENVIAR O PRESET PARA O BICO!")
					endif

				endif

			EndIf

		elseif cModelo == "03" // se a concentradora for Fusion

			cNumLogico	:= AllTrim(aString[1])
			cLado		:= AllTrim(aString[2])

			if aString[3] > 0 // se o valor foi informado
				cValor	:= cValToChar(aString[3])
			else
				cValor	:= "FULL"
			endif

			cStrEnvio := "2||POST|REQ_PUMP_PRESET_ID_" + PADL(cLado,3,"0") + "|||TY=MONEY|VA=" + cValor + "|HO=" + cNumLogico + "|^"
			cStrEnvio := PADL(cValToChar(Len(cStrEnvio)),5,"0") + "|5|" + cStrEnvio

			if lLogAbast
				Conout(" >> COMANDO " + cStrEnvio + " - LIBERACAO DE BICO (PRESET)")
			endif

			// envio comando para fusion
			lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

			if lConect

				if Empty(cRet)
					lRet := .T.
					if lLogAbast
						Conout(" >> PRESET ENVIADO COM SUCESSO!")
					endif
				elseif lLogAbast
					Conout(" >> NAO FOI POSSIVEL ENVIAR O PRESET PARA O BICO!")
				endif

			elseif lLogAbast
				Conout(" >> CONEXAO NAO REALIZADA")
			endif

		elseif lLogAbast
			Conout(" >> MODELO DA CONCENTRADORA INVALIDO")
		endif

	elseif lLogAbast
		Conout(" >> STATUS: DESATIVADO")
	endif

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(lRet)



/*/{Protheus.doc} CheckSum
Função que calcula o checksum da string passada como parametro.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cString, characters, String
@type function
/*/
Static Function CheckSum(cString)

	Local nCheckSum	:= 0
	Local cCheckSum	:= cString
	Local cRet 		:= ""
	Local nX		:= 1
	Local nPosIni	:= 0
	Local nPosFim	:= 0

// calculo o checksum, que é a somatória dos códigos ASC2 de todos os caracteres da string
	For nX := 1 To Len(cCheckSum)

		nCheckSum += ASC(SubStr(cCheckSum,nX,1))

	Next nX

// transformo para hexadecimal
	cCheckSum 	:= NToC(nCheckSum,16,4)

// pego os dois últimos caracteres
	if !Empty(cCheckSum)

		nPosIni	:= Len(cCheckSum) - 1
		nPosFim	:= 2
		cRet	:= SubStr(cCheckSum,nPosIni,nPosFim)

	endif

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(cRet)


/*/{Protheus.doc} AbastCBC
Função que faz a leitura do abastecimentos da concentradora CBC
String de envio: (&A) para CBC05 ou (&A67) para CBC06
String de próximo abastecimento (ponteiro): (&I)
Retorno: (ATTTTTT LLLLLLPPPPVVCCCCBBDDHHMMNNRRRREEEEEEEEEESSIIIIIIIIIIIIIIIIMMMMPPKK)
ou “(0)” se nenhum abastecimento na memória.
A ------------------- Cabeçalho
TTTTTT -------------- Total a Pagar; (bombas mecânicas retornam “000000”);
LLLLLL -------------- Volume abastecido (Litros);
PPPP ---------------- Preço unitário;
VV ------------------ Código de vírgula (aplicável aos campos T,L e P);
CCCC ---------------- Tempo de abastecimento (Hexadecimal);
BB ------------------ Código de bico;
DD ------------------ Dia;
HH ------------------ Hora;
MM ------------------ Minuto;
NN ------------------ Mês;
RRRR ---------------- Número do abastecimento;
EEEEEEEEEE ---------- Encerrante do bico (com duas casas decimais);
SS ------------------ Status da integridade da memória de abastecimentos. (00=Ok);
IIIIIIIIIIIIIIII ---- Código do cartão que autorizou o abastecimento;
MMMM ---------------- Número da leitura de identificação;
PP ------------------ Status de integridade de memória de identificadores. (00=Ok);
KK ------------------ Checksum.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cConcent, characters, Código da concentradora
@param cModelo, characters, Modelo da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@type function
/*/
Static Function AbastCBC(cConcent,cModelo,cIP,nPorta)

	Local cRetorno 		:= ""
	Local lConect		:= .T.
	Local cStrAbast		:= ""
	Local cStrProx		:= "(&I)" //Incremento - Este comando é utilizado para passar o ponteiro de leitura para o próximo abastecimento.

	While .T.

		cRetorno 	:= ""

		if cModelo == "01" // CBC-05

			cStrAbast	:= "(&A)"
			if lLogAbast
				Conout(" >> COMANDO " + cStrAbast + " - LEITURA DE ABASTECIMENTOS")
			endif

			// chamo a função que faz conexão via socket
			lConect := U_XSocketP(cIP,nPorta,cStrAbast,@cRetorno)

			If ValType(cRetorno) <> "C" .OR. Empty(cRetorno)
				cRetorno := ""
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			Else

				cRetorno := StrTran(cRetorno,"(0)","")
				cRetorno := StrTran(cRetorno,"(","")
				cRetorno := StrTran(cRetorno,")","")

			EndIf

		elseif cModelo == "02" // Horustech/CBC-06

			cStrAbast	:= "(&A67)"
			if lLogAbast
				Conout(" >> COMANDO " + cStrAbast + " - LEITURA DE ABASTECIMENTOS")
			endif

			// chamo a função que faz conexão via socket
			lConect := U_XSocketP(cIP,nPorta,cStrAbast,@cRetorno)

			If ValType(cRetorno) <> "C" .OR. Empty(cRetorno)
				cRetorno := ""
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			Else

				cRetorno := StrTran(cRetorno,"(0)","")
				cRetorno := StrTran(cRetorno,"(","")
				cRetorno := StrTran(cRetorno,")","")
				cRetorno := SubStr(cRetorno,2,68)

			EndIf

		endif

		// se a variável de retorno estiver preenchida, tem abatecimento
		if !Empty(cRetorno)

			if IncluiAbCBC(cRetorno,cConcent)
				// pulo para o próximo abastecimento
				lConect := U_XSocketP(cIP,nPorta,cStrProx,@cRetorno)

				// mostro uma linha em branco no console
				if lLogAbast
					Conout("")
				endif
			else
				if lLogAbast
					Conout(" >> NAO FOI POSSIVEL INCLUIR ABASTECIMENTO")
				endif
				Exit //sai do While .T.
			endif

		else
			if lLogAbast
				Conout(" >> NAO EXISTEM ABASTECIMENTOS")
			endif
			Exit //sai do While .T.
		endif

	EndDo

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return()

/*/{Protheus.doc} AbCBCNew
Função que faz a leitura do abastecimentos da concentradora CBC
String de envio: (&A) para CBC05 ou (&A67) para CBC06
String de próximo abastecimento (ponteiro): (&I)
Retorno: (ATTTTTT LLLLLLPPPPVVCCCCBBDDHHMMNNRRRREEEEEEEEEESSIIIIIIIIIIIIIIIIMMMMPPKK)
ou “(0)” se nenhum abastecimento na memória.
A ------------------- Cabeçalho
TTTTTT -------------- Total a Pagar; (bombas mecânicas retornam “000000”);
LLLLLL -------------- Volume abastecido (Litros);
PPPP ---------------- Preço unitário;
VV ------------------ Código de vírgula (aplicável aos campos T,L e P);
CCCC ---------------- Tempo de abastecimento (Hexadecimal);
BB ------------------ Código de bico;
DD ------------------ Dia;
HH ------------------ Hora;
MM ------------------ Minuto;
NN ------------------ Mês;
RRRR ---------------- Número do abastecimento;
EEEEEEEEEE ---------- Encerrante do bico (com duas casas decimais);
SS ------------------ Status da integridade da memória de abastecimentos. (00=Ok);
IIIIIIIIIIIIIIII ---- Código do cartão que autorizou o abastecimento;
MMMM ---------------- Número da leitura de identificação;
PP ------------------ Status de integridade de memória de identificadores. (00=Ok);
KK ------------------ Checksum.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cConcent, characters, Código da concentradora
@param cModelo, characters, Modelo da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@type function
/*/
Static Function AbCBCNew(cConcent,cModelo,cIP,nPorta)

	Local cRetorno 		:= ""
	Local cStrAbast		:= ""
	Local cStrProx		:= "(&I)" //Incremento - Este comando é utilizado para passar o ponteiro de leitura para o próximo abastecimento.
	Local oSockCBC		:= TPDVSock():New(nPorta,cIP)
	Local cRetoBkp		:= ""

	If oSockCBC:ConnSock() //conecta na concentradora

		While .T. .and. oSockCBC:IsConn()

			cRetorno 	:= ""
			if cModelo == "01" // CBC-05
				cStrAbast	:= "(&A)"
				if lLogAbast
					Conout(" >> COMANDO " + cStrAbast + " - LEITURA DE ABASTECIMENTOS")
				endif
			elseif cModelo == "02" // Horustech/CBC-06
				cStrAbast	:= "(&A67)"
				if lLogAbast
					Conout(" >> COMANDO " + cStrAbast + " - LEITURA DE ABASTECIMENTOS")
				endif
			endif

			// chamo a função que faz conexão via socket
			cRetorno := oSockCBC:Send(cStrAbast)
			//cRetorno := oSockCBC:LastReturn()

			If ValType(cRetorno) <> "C" .OR. Empty(cRetorno)
				cRetorno := ""
				if lLogAbast
					Conout(" >> CONEXAO NAO REALIZADA")
				endif
			Else
				cRetorno := StrTran(cRetorno,"(0)","")
				cRetorno := StrTran(cRetorno,"(","")
				cRetorno := StrTran(cRetorno,")","")
				If cModelo == "02" // Horustech/CBC-06
					cRetorno := SubStr(cRetorno,2,68)
				EndIf
			EndIf

			// se a variável de retorno estiver preenchida, tem abatecimento
			If !Empty(cRetorno) 
				If AllTrim(cRetoBkp) <> AllTrim(cRetorno)
					If IncluiAbCBC(cRetorno,cConcent)
						if lLogAbast
							Conout(" >> ABASTECIMENTO INCLUIDO COM SUCESSO:"+cRetorno)
						endif
					Else
						if lLogAbast
							Conout(" >> NAO FOI POSSIVEL INCLUIR ABASTECIMENTO")
						endif
						Exit //sai do While .T.
					EndIf
				Else
					if lLogAbast
						Conout(" >> ABASTECIMENTO JÁ INCLUIDO: "+cRetorno)
					endif
					Exit //sai do While .T.
				EndIf
			Else
				if lLogAbast
					Conout(" >> NAO EXISTEM ABASTECIMENTOS")
				endif
				Exit //sai do While .T.
			EndIf

			// pulo para o próximo abastecimento (ponteiro)
			oSockCBC:Send(cStrProx)
			// mostro uma linha em branco no console
			if lLogAbast
				Conout(" >> PULO PARA O PROXIMO ABASTECIMENTO (PONTEIRO)")
			endif

			cRetoBkp := cRetorno

		EndDo

	Elseif lLogAbast
		Conout(" >> FALHA NA CONEXAO COM A CONCENTRADORA: "+cConcent)
	EndIf

	oSockCBC:DisConnSock()

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return()

Static Function IncluiAbCBC(cRetorno,cConcent)

	Local lRet			:= .F.
	//Local cCodVirgula	:= ""
	Local nDecQtd		:= 0
	Local nDecPrc		:= 0
	Local nDecTot		:= 0
	Local cNLogic		:= ""
	Local nQtdVen 	   	:= 0
	Local nPrcVen 		:= 0
	Local nPrcTab		:= 0
	Local nTotal 		:= 0
	Local nEncerra 		:= 0
	Local cDia 			:= ""
	Local cMes 			:= ""
	Local cHora 		:= ""
	Local cMinuto 		:= ""
	Local cNumAb 		:= ""
	Local cIdentifid	:= ""
	Local cNumIdent		:= ""
	Local cNumBico 		:= ""
	Local cProduto 		:= ""
	Local dDataAbast	:= CtoD("")
	Local dDataRef		:= Date()
	Local cHoraRef		:= Time()
	Local cHoraMin		:= SuperGetMV("MV_XFCHHMI", .F./*lHelp*/, "24:00:00") //Horário mínimo para processar o Fechamento Diário do Posto. A partir desse horario, os abastecimentos caem automaticamente para o dia seguinte.

	Local cPasta   := "\AUTOCOM"
	Local cErroLOG := "\AUTOCOM\CONCENTRADORA"  //+"LOG" + cEmpAnt + StrTran(Alltrim(cFilAnt)," ","")
	Local cNomeArq := ""
	Local cTexto   := ""
	Local lPrcDifTab    := SuperGetMV( "MV_XPDFTAB", , .F. ) // Permite baixa de abastecimento cujo o preço de bomba é diferente do preço de tabela
	Local nTentativas := 10 //numero de tentativa para correção
	Local nQtdBkp := 0
	Local aCampos := {}
	Local lBicoAtivo := .F.

	If !ExistDir(cPasta)
		nRet := MakeDir( cPasta )
		If nRet != 0
			if lLogAbast
				Conout( "Não foi possível criar o diretório "+cPasta+". Erro: " + cValToChar( FError() ) )
			endif
		EndIf
	EndIf

	If !ExistDir(cErroLOG )
		nRet := MakeDir( cErroLOG  )
		If nRet != 0
			if lLogAbast
				Conout( "Não foi possível criar o diretório "+cErroLOG +". Erro: " + cValToChar( FError() ) )
			endif
		EndIf
	EndIf

	if lLogAbast
		Conout(" >> RETORNO: " + cRetorno)
	endif

	Conout(">>ABASTECIMENTOS")

	cCodVirgula	:= SubStr(cRetorno,17,2)
	conout(">> numero logico: " + PadR(SubStr(cRetorno,23,2),TamSX3("MIC_NLOGIC")[1]))
	Conout(">> codigo de virgula: " + cCodVirgula)

	// Wellington Gonçalves dia 03/11/2015.
	// Este código de vírgula está dando problema na CBC de belém, pois as bombas estão configuradas com 2 casas, mas a concentradora com 3
	// faz o tratamento das casas decimais
	if MHX->MHX_TPBOMB == '1' //bomba automatica
		cCodVirgula	:= SubStr(cRetorno,17,2)
		if cCodVirgula == "3A"
			nDecQtd := 2
			nDecPrc	:= 3
		elseif cCodVirgula == "3E"
			nDecQtd := 3
			nDecPrc	:= 3
		elseif cCodVirgula == "2A"
			nDecQtd := 2
			nDecPrc	:= 2
		elseif cCodVirgula == "2E"
			nDecQtd := 3
			nDecPrc	:= 2
		else
			nDecQtd := 2
			nDecPrc	:= 2
		endif
	endif
	
	cNLogic		:= PadR(SubStr(cRetorno,23,2),TamSX3("MIC_NLOGIC")[1])

	// posiciono na tabela de bicos
	if MIC->(FieldPos("MIC_XDECPR")) > 0
		MIC->(DbOrderNickName("MIC_001")) //MIC_FILIAL+MIC_XCONCE+MIC_LADO+MIC_NLOGIC
		if MIC->(DbSeek(xFilial("MIC") + cConcent + Space(TamSX3("MIC_LADO")[1]) + cNLogic)) 
			//.AND. MIC->MIC_STATUS == "1" // se o bico estiver ativo

			lBicoAtivo := .F.
			While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_XCONCE+MIC->MIC_LADO+MIC->MIC_NLOGIC == xFilial("MIC") + cConcent + Space(TamSX3("MIC_LADO")[1]) + cNLogic
				if  ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataAbast) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataAbast))
					lBicoAtivo := .T.
					EXIT
				endif
				MIC->(DBSkip())
			EndDO

			if lBicoAtivo
				if nDecQtd == 0
					nDecQtd := MIC->MIC_XDECVO // casas decimais da quantidade
				endif
				if nDecPrc == 0
					nDecPrc := MIC->MIC_XDECPR // casas decimais da quantidade
				endif
				if nDecTOT == 0
					nDecTOT := MIC->MIC_XDECTO // casas decimais da quantidade
				endif
			endif
		endif
	endif
	
	//Tratamento para casas decimais, com origem no cadastro da concentradora
	if nDecQtd == 0
		nDecQtd := MHX->MHX_DECVOL // casas decimais da quantidade
		if nDecQtd == 0
			nDecQtd := 3
		endif
	endif
	if nDecPrc == 0
		nDecPrc	:= MHX->MHX_DECPRC // casas decimais do preço unitário
		if nDecPrc == 0
			nDecPrc := 3
		endif
	endif
	if nDecTOT == 0
		nDecTOT	:= MHX->MHX_DECTOT // casas decimais do preço unitário
		if nDecTOT == 0
			nDecTOT := 2
		endif
	endif

	// Wellington Gonçalves 02/11/2015, pois nem todas as bombas obedecem o código de vírgula da CBC
	// a quantidade será calculada de acordo com o valor total e o valor unitário
	// nQtdVen := Val(SubStr(cRetorno,7,6))/ (10 ^ (nDecQtd - 1))

	nPrcVen 	:= Val(SubStr(cRetorno,13,4))/ (10 ^ nDecPrc) //preço de venda da bomba
	nTotal 		:= Val(SubStr(cRetorno,1,6))/ (10 ^ nDecTOT) //preço total do abastecimento
	nQtdVen		:= Round( (nTotal / nPrcVen) , nDecQtd ) //litragem (quantidade de abastecimento)

	// Wellington Gonçalves 04/11/2015
	// tratamento para quando a CBC não enviar o valor total, está acontecendo em alguns bicos em belém
	If nTotal == 0
		if lLogAbast
			Conout("****  ATENCAO! >> VALOR TOTAL ZERADO, O CALCULO DA QUANTIDADE SERA FEITO PELO SISTEMA! ****")
		endif
		// considero a quantidade que a concentradora me enviou, mesmo sendo apenas com duas casas decimais
		nQtdVen := Val(SubStr(cRetorno,7,6)) / (10 ^ nDecQtd)
		// calculo o valor total e trunco na segunda casa decimal
		nTotal	:= NoRound(nPrcVen * nQtdVen , nDecTOT)
	EndIf

	// ajusta o TOTAL para o numero de casas decimais que o sistema trabalha: L2_VLRITEM
	nTotal := A410Arred(nTotal,"L2_VLRITEM")

	// tratamento para não haver divergencia entre o total da bomba e o total do cupom

	// quando TOTAL é maior que QTD x PREÇO
	nTentativas := 10 //numero de tentativa para correção
	nQtdBkp := nQtdVen
	While nTentativas > 0 .and. nTotal > A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
		if lLogAbast
			conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO TOTAL ["+cValToChar(nTotal)+"], FOI ADICIONADO 0,001 NA QUANTIDADE")
			conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ANTES ["+cValToChar(nQtdVen)+"]")
		endif
		nQtdVen += 0.001
		if lLogAbast
			conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD DEPOIS ["+cValToChar(nQtdVen)+"]")
		endif
		nTentativas --
		If nTotal = A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
			Exit //sai do While
		ElseIf A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM") > nTotal //não funcionou, aborta o ajuste
			nQtdVen := nQtdBkp
			if lLogAbast
				conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ["+cValToChar(nQtdVen)+"] - ABORTA AJUSTE")
			endif
			Exit //sai do While
		EndIf
	EndDo

	// quando TOTAL é menor que QTD x PREÇO
	nTentativas := 10 //numero de tentativa para correção
	nQtdBkp := nQtdVen
	While nTentativas > 0 .and. nTotal < A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
		if lLogAbast
			conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO TOTAL ["+cValToChar(nTotal)+"], FOI SUBTRAIDO 0,001 NA QUANTIDADE")
			conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ANTES ["+cValToChar(nQtdVen)+"]")
		endif
		nQtdVen -= 0.001
		if lLogAbast
			conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD DEPOIS ["+cValToChar(nQtdVen)+"]")
		endif
		nTentativas --
		If nTotal = A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
			Exit //sai do While
		ElseIf A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM") < nTotal //não funcionou, aborta o ajuste
			nQtdVen := nQtdBkp
			if lLogAbast
				conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ["+cValToChar(nQtdVen)+"] - ABORTA AJUSTE")
			endif
			Exit //sai do While
		EndIf
	EndDo

	cDia 		:= SubStr(cRetorno,25,2)
	cMes 		:= SubStr(cRetorno,31,2)
	cHora 		:= SubStr(cRetorno,27,2)
	cMinuto 	:= SubStr(cRetorno,29,2)
	cNumAb 		:= SubStr(cRetorno,33,4)
	nEncerra 	:= Val(SubStr(cRetorno,37,8)) + ( Val(SubStr(cRetorno,45,2)) / 100 )
	dDataAbast	:= ctod(cDia + "/" + cMes + "/" + StrZero(Year(dDataRef),4))
	cIdentifid	:= SubStr(cRetorno,49,16)
	cNumIdent	:= SubStr(cRetorno,67,4)

	// a concentradora nao envia o ano, por isso o abastecimento pode ser do ano anterior e nao do ano da database
	// não está sendo considerado a variável dDataBase, e sim a função Date()
	// existe uma situação onde o job é startado antes da meia noite, e é finalizado após a meia noite
	// neste caso, a variável dDataBase não é atualizada, fazendo com que entre nesta tratativa abaixo, subtraindo 1 ano da data do abastecimento
	// com a utilização da função Date(), que pega a data do servidor, não deverá mais ocorrer esta divergência

		/*	09/02/2017 > Pablo Cavalcante - adicionado uma melhoria para validar também o mes e dia.
			As situações em que deve subtrair ano ou adicionar ano são as seguintes:

            Ex.:
			1- 	dDataRef 	31/12/2017
				dDataAbast	01/01/2017 -> o ano correto é o ano 2018

			2- 	dDataRef 	01/01/2018
				dDataAbast	31/12/2018 -> o ano correto é o ano 2017
		*/
	if dDataAbast < dDataRef .and. MesDia(dDataRef) == "1231"
		dDataAbast := YearSum(dDataAbast,1)
		if lLogAbast
			Conout(" - TRATAMENTO PARA AJUSTAR A DATA, FOI SOMADO 1 ANO NA DATA DO ABASTECIMENTO")
			Conout("   dDataAbast: "+DtoC(dDataAbast))
			Conout("   dDataRef:   "+DtoC(dDataRef))
		endif
	elseif dDataAbast > dDataRef .and. MesDia(dDataRef) == "0101"
		dDataAbast := YearSub(dDataAbast,1)
		if lLogAbast
			Conout(" - TRATAMENTO PARA AJUSTAR A DATA, FOI SUBTRAIDO 1 ANO NA DATA DO ABASTECIMENTO")
			Conout("   dDataAbast: "+DtoC(dDataAbast))
			Conout("   dDataRef:   "+DtoC(dDataRef))
		endif
	else
		if lLogAbast
			Conout(" - DATA DO ABASTECIMENTO E DATA DE REFERENCIA (DATE)...")
			Conout("   dDataAbast: "+DtoC(dDataAbast))
			Conout("   dDataRef:   "+DtoC(dDataRef))
		endif
	endif

	// posiciono na tabela de bicos
	MIC->(DbOrderNickName("MIC_001")) //MIC_FILIAL+MIC_XCONCE+MIC_LADO+MIC_NLOGIC
	if MIC->(DbSeek(xFilial("MIC") + cConcent + Space(TamSX3("MIC_LADO")[1]) + cNLogic)) 
		//.AND. MIC->MIC_STATUS == "1" // se o bico estiver ativo

		lBicoAtivo := .F.
		While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_XCONCE+MIC->MIC_LADO+MIC->MIC_NLOGIC == xFilial("MIC") + cConcent + Space(TamSX3("MIC_LADO")[1]) + cNLogic
			if  ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataAbast) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataAbast))
				lBicoAtivo := .T.
				EXIT
			endif
			MIC->(DBSkip())
		EndDO

		if lBicoAtivo
			MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN
			If MHZ->(DbSeek( xFilial("MHZ") + MIC->MIC_CODTAN )) ;
				.AND. ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dDataAbast) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dDataAbast))

				if nQtdVen > 0 //-- tratamento para não gravar abastecimento zerado

					// adiciono a casa do milhao
					nEncerra := nEncerra + (MIC->MIC_XMILHA * 1000000)

					cNumBico	:= MIC->MIC_CODBIC
					cProduto	:= MHZ->MHZ_CODPRO

					if lLogAbast
						Conout(" >> DADOS DO ABASTECIMENTO: ")

						Conout(" - Bico: " 		   	   		+ cNumBico )
						Conout(" - N. Logico: " 		   	+ cNLogic )
						Conout(" - Litros: " 		   		+ cValToChar(nQtdVen) )
						Conout(" - Valor Unitario: "  		+ cValToChar(nPrcVen) )
						Conout(" - Valor Total: " 			+ cValToChar(nTotal) )
						Conout(" - Dia: " 					+ cDia )
						Conout(" - Mes: " 					+ cMes )
						Conout(" - Hora: " 			   		+ cHora )
						Conout(" - Minuto: " 				+ cMinuto )
						Conout(" - Numero abastecimento: " 	+ cNumAb )
						Conout(" - Identfid: " 			    + cIdentifid )
						Conout(" - Encerrante: "   			+ cValToChar(nEncerra) )
						if MIC->MIC_XMILHA > 0
							Conout(" - Encerrante sem milhao: " + cValToChar( (nEncerra-(MIC->MIC_XMILHA * 1000000)) ) )
						endif
					endif

					nPrcTab := U_URetPrec(cProduto,"",.F.)

					If !lPrcDifTab .and. nPrcTab <> nPrcVen
						cTexto := " " + CRLF ;
							+ ">> EXISTE DIFERENCA DE PRECO ENTRE: PRECO DE BICO x PRECO DE TABELA << " + CRLF ;
							+ " " + CRLF ;
							+ "DATA: "+DtoC(Date())+"" + CRLF ;
							+ "HORA: "+Time()+"" + CRLF ;
							+ " " + CRLF ;
							+ "CONCENTRADORA: "+cConcent+"" + CRLF ;
							+ "NUM. BICO: "+cNumBico+"" + CRLF ;
							+ "NUM. LOGICO: "+cNLogic+"" + CRLF ;
							+ "PRODUTO: "+AllTrim(cProduto)+" - "+ MHZ->MHZ_DESPRO + CRLF ;
							+ " " + CRLF ;
							+ "PRECO BICO: "+cValToChar(nPrcVen)+"" + CRLF ;
							+ "PRECO TABELA: "+cValToChar(nPrcTab)+"" + CRLF ;
							+ " " + CRLF ;
							+ "STRING DE RETORNO: "+cRetorno+"" + CRLF ;
							+ " " + CRLF ;
							+ " " + CRLF

						if lLogAbAuto
							cNomeArq := "LOG_TRETE001_"+DtoS(dDataBase)+"_"+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)+".log"
							U_UCriaLog(cErroLOG+"\"/*cPasta*/,cNomeArq/*cNomeArq*/,cTexto/*cTexto*/)
						endif
					EndIf

					aCampos := {}
					aAdd( aCampos, { 'MID_FILIAL'	, xFilial("MID") 						} )
					aAdd( aCampos, { 'MID_CODBIC' 	, cNumBico  							} )
					aAdd( aCampos, { 'MID_DATACO' 	, Iif(cHoraRef>cHoraMin,DaySum(dDataAbast,1),dDataAbast) } )
					aAdd( aCampos, { 'MID_HORACO' 	, cHora + ":" + cMinuto					} )
					aAdd( aCampos, { 'MID_XPROD' 	, cProduto								} )
					aAdd( aCampos, { 'MID_CODBOM' 	, MIC->MIC_CODBOM  		   				} )
					aAdd( aCampos, { 'MID_XCONCE' 	, cConcent		  		   				} )
					aAdd( aCampos, { 'MID_CODTAN' 	, MIC->MIC_CODTAN						} )
					aAdd( aCampos, { 'MID_NLOGIC' 	, cNLogic  			   					} )
					aAdd( aCampos, { 'MID_LADBOM' 	, MIC->MIC_LADO  			   			} )
					aAdd( aCampos, { 'MID_LITABA' 	, nQtdVen  								} )
					aAdd( aCampos, { 'MID_PREPLI' 	, nPrcVen  								} )
					aAdd( aCampos, { 'MID_TOTAPA' 	, nTotal								} )
					aAdd( aCampos, { 'MID_ENCFIN' 	, nEncerra  		   					} )
					aAdd( aCampos, { 'MID_RFID' 	, cIdentifid		   					} )
					aAdd( aCampos, { 'MID_DTBASE' 	, dDataRef	 							} )
					aAdd( aCampos, { 'MID_LEITUR' 	, PadL(AllTrim(cNumIdent),TamSx3("MID_LEITUR")[1],"0") } )
					aAdd( aCampos, { 'MID_ENCINI'   , (nEncerra-nQtdVen)													   } ) //Encerrante inicial
					aAdd( aCampos, { 'MID_NUMORC'	, "P" } ) //Abastecimento Pendente
					aAdd( aCampos, { 'MID_CODANP'	, MHZ->MHZ_CODANP } ) 
					aAdd( aCampos, { 'MID_PBIO'		, MHZ->MHZ_PBIO } ) 
					aAdd( aCampos, { 'MID_UFORIG'	, MHZ->MHZ_UFORIG } ) 
					aAdd( aCampos, { 'MID_PORIG'	, MHZ->MHZ_PORIG } ) 
					aAdd( aCampos, { 'MID_INDIMP'	, MHZ->MHZ_INDIMP } ) 
					aAdd( aCampos, { 'MID_ENVSPE'	, "S" } ) //Envia SPED: S-Sim;N-Nao

					// faço a gravação do abastecimento
					If U_GrvAbMID(aCampos)
						if lLogAbast
							Conout(" >> ABASTECIMENTO INCLUIDO COM SUCESSSO: "+MID->MID_CODABA+"!!!")
						endif
						lRet := .T.
					EndIf

				else
					if lLogAbast
						Conout(" >> ABASTECIMENTO ZERADO!")
						Conout(" >> DADOS DO ABASTECIMENTO: ")
						Conout(" - Bico: " 		   	   		+ cNumBico )
						Conout(" - N. Logico: " 		   	+ cNLogic )
						Conout(" - Litros: " 		   		+ cValToChar(nQtdVen) )
						Conout(" - Valor Unitario: "  		+ cValToChar(nPrcVen) )
						Conout(" - Valor Total: " 			+ cValToChar(nTotal) )
						Conout(" - Dia: " 					+ cDia )
						Conout(" - Mes: " 					+ cMes )
						Conout(" - Hora: " 			   		+ cHora )
						Conout(" - Minuto: " 				+ cMinuto )
						Conout(" - Numero abastecimento: " 	+ cNumAb )
						Conout(" - Identfid: " 			    + cIdentifid )
						Conout(" - Encerrante: "   			+ cValToChar(nEncerra) )
					endif
					lRet := .T. //coloco como OK, pois tem que pular para o proximo abastecimento...
				endif

			elseif lLogAbast
				Conout(" >> GRUPO DE TANQUE " + AllTrim(MIC->MIC_CODTAN) + " INVALIDO OU DESATIVADO")
			endif
		else
			if lLogAbast
				Conout(" >> NUMERO LOGICO " + AllTrim(cNLogic) + " NAO CADASTRADO OU INATIVO")
			endif
		endif
	else
		if lLogAbast
			Conout(" >> NUMERO LOGICO " + AllTrim(cNLogic) + " NAO CADASTRADO")
		endif
		lRet := .T.
	endif

	//Sleep(2000)

Return lRet


/*/{Protheus.doc} AbastFusion
Função que faz a leitura do abastecimento da Fusion.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cConcent, characters, Código da concentradora
@param cIp, characters, IP
@param nPorta, numeric, Porta
@param cDataLimite, characters, data limite para considerar abastecimentos (considera a partir da data ??)
@param cHoraLimite, characters, hora limite para considerar abastecimentos (considera a partir da hora ??)
@type function
/*/
Static Function AbastFusion(cConcent,cIp,nPorta,cDataLimite,cHoraLimite)

	Local aBombas		:= {}
	Local aAbastecimento:= {}
	Local aAbast		:= {}
	Local nPosQtdBomba	:= 0
	Local nQtdBomba		:= ""
	Local cStrAbast		:= ""
	Local cStrAbAnt		:= ""
	Local cLadoBomba	:= ""
	Local cNumBomba     := "" //numero da bomba que esta sendo realizado leitura
	Local cIdentifid	:= ""
	Local nQtdVen			:= 0
	Local nPrcVen		:= 0
	Local nPrcTab		:= 0
	Local cNumBico 		:= ""
	Local cProduto 		:= ""
	Local nPosIdAbast	:= 0
	Local nPosError		:= 0
	Local nPosIdentif	:= 0
	Local nX			:= 0
	Local nY			:= 0
	Local nTotal		:= 0
	Local cStrBomba		:= ""
	Local cRetorno		:= ""
	Local nTamLado		:= TamSX3("MIC_LADO")[1]
	Local nTamNLogic	:= TamSX3("MIC_NLOGIC")[1]
	Local dDataRef		:= Date()
	Local cNLogic		:= ""
	Local lJaCadastrado := .F.

	Local cHoraRef		:= Time()
	Local cHoraMin		:= SuperGetMV("MV_XFCHHMI", .F./*lHelp*/, "24:00:00") //Horário mínimo para processar o Fechamento Diário do Posto.

	Local cPasta   := "\AUTOCOM"
	Local cErroLOG := "\AUTOCOM\CONCENTRADORA"  //+"LOG" + cEmpAnt + StrTran(Alltrim(cFilAnt)," ","")
	Local cNomeArq := ""
	Local cTexto   := ""
	Local lPrcDifTab := SuperGetMV( "MV_XPDFTAB", , .F. ) // Permite baixa de abastecimento cujo o preço de bomba é diferente do preço de tabela
	Local nTentativas := 10 //numero de tentativa para correção
	Local nQtdBkp := 0
	Local lBicoAtivo := .F.

	If !ExistDir(cPasta)
		nRet := MakeDir( cPasta )
		If nRet != 0
			if lLogAbast
				Conout( "Não foi possível criar o diretório "+cPasta+". Erro: " + cValToChar( FError() ) )
			endif
		EndIf
	EndIf

	If !ExistDir(cErroLOG )
		nRet := MakeDir( cErroLOG  )
		If nRet != 0
			if lLogAbast
				Conout( "Não foi possível criar o diretório "+cErroLOG +". Erro: " + cValToChar( FError() ) )
			endif
		EndIf
	EndIf

// monto a string para ler a quantidade de bombas
	cStrBomba := "00034|5|2||POST|REQ_FCRT_PUMPS_CONFIG||||^"

	if lLogAbast
		Conout("")
		Conout(" >> COMANDO CONFIGURACAO DO PATIO (COMANDO) - cStrBomba: " + cStrBomba + "")
		Conout("")
	endif

// envio comando para fusion
	U_XSocketP(cIp,nPorta,cStrBomba,@cRetorno)

	if lLogAbast
		Conout("")
		Conout(" >> COMANDO CONFIGURACAO DO PATIO (RETORNO) - cRetorno: " + cRetorno + "")
		Conout("")
	endif

// transformo a string de retorno em array
	aBombas := StrToKarr(cRetorno,"|")

// valido se o array tem pelo menos uma posição para não dar erro
	if Len(aBombas) > 0

		// encontro a TAG referente à quantidade de bombas
		nPosQtdBomba := aScan(aBombas,{|x| "PUMPS=" $ AllTrim(x)})

		// separo a quantidade de bombas
		nQtdBomba := Val(SubStr(aBombas[nPosQtdBomba],7,Len(aBombas[nPosQtdBomba])))
		
		if lLogAbast
			Conout("")
			Conout(" >> NUMERO DE BOMBAS NO PATIO: " + cValToChar(nQtdBomba))
			Conout("")
		endif

		// percorro todas as bombas cadastradas na Fusion
		For nX := 1 To nQtdBomba
			cRetorno := ""
			Sleep(1000)

			// mostro uma linha em branco no console
			if lLogAbast
				Conout("")
				Conout(" >> LENDO ABASTECIMENTOS DA BOMBA " + PADL(cValToChar(nX),3,"0"))
				Conout("")
			endif

			aAbastecimento := {}

			// monto a string para ler o último abastecimento do lado da bomba posicionada
			cStrAbast := "2||POST|REQ_PUMP_GET_LAST_SALE_ID_" + PADL(cValToChar(nX),3,"0") + "||||^"
			cStrAbast := PADL(cValToChar(Len(cStrAbast)),5,"0") + "|5|" + cStrAbast
			
			if lLogAbast
				Conout("")
				Conout(" >> COMANDO LEITURA DE ABASTECIMENTOS (COMANDO) - cStrAbast: " + cStrAbast + "")
				Conout("")
			endif

			// envio comando para fusion
			U_XSocketP(cIp,nPorta,cStrAbast,@cRetorno)

			if lLogAbast
				Conout("")
				Conout(" >> COMANDO LEITURA DE ABASTECIMENTOS (RETORNO) - cRetorno: " + cRetorno + "")
				Conout("")
			endif

			// transformo a string de retorno em array
			aAbast := StrToKarr(cRetorno,"|")

			cNumBomba := PADL(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "PM="})],"PM=",""),nTamLado,"0") //numero da bomba que esta sendo realizado leitura

			// posiciono na tabela de bicos
			MIC->(DbOrderNickName("MIC_001")) //MIC_FILIAL+MIC_XCONCE+MIC_LADO+MIC_NLOGIC
			if !MIC->(DbSeek(xFilial("MIC") + cConcent + cNumBomba ))  //nao encontrar
					//.OR. MIC->MIC_STATUS != "1" // se o bico estiver inativo

				if lLogAbast
					Conout("")
					Conout(" >> NUMERO DE BOMBA (**LADO**) " + AllTrim(cNumBomba) + " NAO CADASTRADO")
					Conout("")
				endif
				Loop //vai para o proximo For nX

			endif
			
			lBicoAtivo := .F.
			While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_XCONCE+MIC->MIC_LADO == xFilial("MIC") + cConcent + cNumBomba
				if  ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataBase) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataBase))
					lBicoAtivo := .T.
					EXIT
				endif
				MIC->(DBSkip())
			EndDO
			if !lBicoAtivo
				if lLogAbast
					Conout("")
					Conout(" >> NUMERO DE BOMBA (**LADO**) " + AllTrim(cNumBomba) + " INATIVADO ")
					Conout("")
				endif
				Loop //vai para o proximo For nX
			endif

			While .T.

				// verifico se existe a TAG que informa se existe erro
				nPosError := aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "RC="})

				if  nPosError > 0 .AND. AllTrim(StrTran(aAbast[nPosError],"RC=","")) <> "OK" // se tiver retornado erro
					if lLogAbast
						Conout("")
						Conout(" >> ERRO NO RETORNO DA CONCENTRADORA: " + StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,4) == "MSG="})],"MSG=",""))
						Conout(" >> Exit - sai do While .T.")
						Conout("")
					endif
					Exit //sai do While .T.
				else

					// encontro as TAG's referentes aos dados do abastecimento
					cLadoBomba	:= PADL(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "PM="})],"PM=",""),nTamLado,"0")
					cNumLogic 	:= PADL(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "HO="})],"HO=",""),nTamNLogic,"0")
					dDataAbast	:= STOD(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "DA="})],"DA=",""))
					cHoraAbast	:= StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "TI="})],"TI=","")
					cHora		:= SubStr(cHoraAbast,1,2)
					cMinuto		:= SubStr(cHoraAbast,3,2)
					nQtdVen		:= Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "VO="})],"VO=",""))
					nPrcVen		:= Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "PU="})],"PU=",""))
					nTotal		:= Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "AM="})],"AM=",""))
					cNumIdent 	:= StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "SA="})],"SA=","")
					nPosIdentif	:= aScan(aAbast,{|x| SubStr(AllTrim(x),1,7) == "PAY_IN="})

					if lLogAbast
						Conout("")
						Conout(" >> NUMERO DE BOMBA (**LADO**) " + AllTrim(cNumBomba) + "")
						Conout(" 	- (LEITURA) NUMERO DE BOMBA: " + AllTrim(cLadoBomba) + "")
						Conout(" 	- (LEITURA) ID DO ABASTECIMENTO: " + cNumIdent)
						Conout(" 	- (LEITURA) DT ABASTECIMENTO: " + DtoC(dDataAbast))
					endif

					If !Empty(cDataLimite) .AND. !Empty(cHoraLimite) .AND. !Empty(DtoS(dDataAbast))

						// se a data do abastecimento for menor que a data limite
						// ou se a data do abastecimento for igual a data limite, mas a hora do abstecimento for menor que a hora limite
						If DtoS(dDataAbast) < cDataLimite .OR. ( DtoS(dDataAbast) == cDataLimite .AND. PADL(cHora,2,"0") < PADL(cHoraLimite,2,"0") )
							if lLogAbast
								Conout("")
								Conout(" >> O PARAMETRO DE DATA E HORA LIMITE ESTAO ATIVADOS.")
								Conout("    SERAO DESCONSIDERADOS OS ABASTECIMENTOS ")
								Conout("    COM DATA INFERIOR A " + DTOC(STOD(cDataLimite)) + " E HORA INFERIOR A " + cHoraLimite + " HORA(AS)" )
							endif
							Exit //sai do While .T.
						EndIf

					EndIf

					if cNumBomba = cLadoBomba //verifica se o abastecimento lido, pertence a bomba que esta sendo realizado leitura

						// posiciono na tabela de bicos
						MIC->(DbOrderNickName("MIC_001")) //MIC_FILIAL+MIC_XCONCE+MIC_LADO+MIC_NLOGIC
						if MIC->(DbSeek(xFilial("MIC") + cConcent + cLadoBomba + cNumLogic ))
								//.AND. MIC->MIC_STATUS == "1" // se o bico estiver ativo
							
							lBicoAtivo := .F.
							While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_XCONCE+MIC->MIC_LADO+MIC->MIC_NLOGIC == xFilial("MIC") + cConcent + cLadoBomba + cNumLogic
								if  ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataAbast) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataAbast))
									lBicoAtivo := .T.
									EXIT
								endif
								MIC->(DBSkip())
							EndDO
							if !lBicoAtivo
								if lLogAbast
									Conout("")
									Conout(" >> NUMERO LOGICO " +AllTrim(cNumLogic) + " DESATIVADO")
									Conout("")
								endif
								Exit //sai do While .T.
							endif

							// posiciono no grupo do tanque
							MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN
							if !MHZ->(DbSeek( xFilial("MHZ") + MIC->MIC_CODTAN ))
								Conout(" >> GRUPO DE TANQUE " + AllTrim(MIC->MIC_CODTAN) + " INVALIDO")
								Conout(" >> Exit - sai do While .T.")
								Conout("")
								Exit //sai do While .T.
							endif

							if !((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dDataAbast) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dDataAbast))
								Conout(" >> GRUPO DE TANQUE " + AllTrim(MIC->MIC_CODTAN) + " DESATIVADO")
								Conout(" >> Exit - sai do While .T.")
								Conout("")
								Exit //sai do While .T.
							endif

						else
							if lLogAbast
								Conout("")
								Conout(" >> NUMERO LOGICO " +AllTrim(cNumLogic) + " NAO CADASTRADO ")
								Conout(" >> Exit - sai do While .T.")
								Conout("")
							endif
							Exit //sai do While .T.

						endif

						//incluido por danilo 05/07/2019
						//Quando reinicia automação, o primeiro abastecimento pendente chega com valor unitario zerado (demais campos certo);
						if nPrcVen == 0 .AND. nQtdVen > 0
							nPrcVen := U_URetPrec(MHZ->MHZ_CODPRO,"",.F.)
							if lLogAbast
								Conout(" - ABASTECIMENTO COM PRECO UNITARIO ZERADO. AJUSTADO PARA PRECO TABELA. ")
							endif
						endif

						// ajusta o TOTAL para o numero de casas decimais que o sistema trabalha: L2_VLRITEM
						nTotal := A410Arred(nTotal,"L2_VLRITEM")

						// tratamento para não haver divergencia entre o total da bomba e o total do cupom

						If nPrcVen == 0
							if lLogAbast
								Conout(" - ESTE ABASTECIMENTO SERA DESCONSIDERADO POIS ESTA COM O PRECO UNITARIO ZERADO")
							endif
						ElseIf nQtdVen == 0
							if lLogAbast
								Conout(" - ESTE ABASTECIMENTO SERA DESCONSIDERADO POIS ESTA COM A QUANTIDADE ZERADA")
							endif
						Else

							// quando TOTAL é maior que QTD x PREÇO
							nTentativas := 10 //numero de tentativa para correção
							nQtdBkp := nQtdVen
							While nTentativas > 0 .and. nTotal > A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
								if lLogAbast
									conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO TOTAL ["+cValToChar(nTotal)+"], FOI ADICIONADO 0,001 NA QUANTIDADE")
									conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ANTES ["+cValToChar(nQtdVen)+"]")
								endif
								nQtdVen += 0.001
								if lLogAbast
									conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD DEPOIS ["+cValToChar(nQtdVen)+"]")
								endif
								nTentativas --
								If nTotal = A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
									Exit //sai do While
								ElseIf A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM") > nTotal //não funcionou, aborta o ajuste
									nQtdVen := nQtdBkp
									if lLogAbast
										conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ["+cValToChar(nQtdVen)+"] - ABORTA AJUSTE")
									endif
									Exit //sai do While
								EndIf
							EndDo

							// quando TOTAL é menor que QTD x PREÇO
							nTentativas := 10 //numero de tentativa para correção
							nQtdBkp := nQtdVen
							While nTentativas > 0 .and. nTotal < A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
								if lLogAbast
									conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO TOTAL ["+cValToChar(nTotal)+"], FOI SUBTRAIDO 0,001 NA QUANTIDADE")
									conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ANTES ["+cValToChar(nQtdVen)+"]")
								endif
								nQtdVen -= 0.001
								if lLogAbast
									conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD DEPOIS ["+cValToChar(nQtdVen)+"]")
								endif
								nTentativas --
								If nTotal = A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
									Exit //sai do While
								ElseIf A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM") < nTotal //não funcionou, aborta o ajuste
									nQtdVen := nQtdBkp
									if lLogAbast
										conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ["+cValToChar(nQtdVen)+"] - ABORTA AJUSTE")
									endif
									Exit //sai do While
								EndIf
							EndDo

						EndIf

						// verifico se existe a TAG com a identificação do vendedor
						if nPosIdentif > 0

							cIdentifid	:= StrTran(aAbast[nPosIdentif],"PAY_IN=","")
							aIdentfid 	:= StrToKarr(cIdentifid,"$")

							// se as tags do identfid vierem preenchidas
							if Len(aIdentfid) > 0

								// verifico a posição da TAG 'TAG='
								nPosIdentif := aScan(aIdentfid,{|x| SubStr(AllTrim(x),1,4) == "TAG="})

								// se a TAG estiver preenchida
								if nPosIdentfid > 0
									cIdentifid := StrTran(aIdentfid[nPosIdentfid],"TAG=","")
									cIdentifid := StrTran(cIdentifid,"~","")
								else
									cIdentifid := ""
								endif

							else
								cIdentifid := ""
							endif

						else
							cIdentifid := ""
						endif

						// verifico se a tag do encerrante está preenchida
						if aScan(aAbast,{|x| SubStr(AllTrim(x),1,4) == "FVO="}) > 0
							nEncerra := Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,4) == "FVO="})],"FVO=",""))
						elseif aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "FV="}) > 0
							nEncerra := Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "FV="})],"FV=",""))
						else
							nEncerra := 0
						endif

						// se o número de identificação do abastecimento vier zerado é porque a bomba está abastecendo
						if cNumIdent <= "0"
							if lLogAbast
								Conout("")
								Conout(" >> NAO EXISTE ABASTECIMENTO ou A BOMBA ESTA EM USO (ABASTECENDO)")
								Conout(" >> Exit - sai do While .T.")
								Conout("")
							endif
							Exit //sai do While .T.
						else

							SET DELETED OFF //-- desabilita filtro do campo DELET

							// valido se o abastecimento já está cadastrado
							MID->(DbOrderNickName("MID_003")) //MID_FILIAL+MID_XCONCE+MID_LEITUR
							lJaCadastrado := MID->(DbSeek(xFilial("MID") + cConcent + PadL(AllTrim(cNumIdent),TamSx3("MID_LEITUR")[1],"0")))

							SET DELETED ON //-- habilita filtro do campo DELET

							if !lJaCadastrado .AND. !Empty(cNumIdent)

								cNumBico := MIC->MIC_CODBIC
								cProduto := MHZ->MHZ_CODPRO
								cNLogic	 := MIC->MIC_NLOGIC

								if nQtdVen > 0 //-- tratamento para não gravar abastecimento zerado

									// adiciono a casa do milhao
									nEncerra := nEncerra + (MIC->MIC_XMILHA * 1000000)

									if lLogAbast
										Conout("")
										Conout(" >> DADOS DO ABASTECIMENTO: ")
										Conout("")
										Conout(" - Bico: " 		   	   		+ MIC->MIC_CODBIC )
										Conout(" - Litros: " 		   		+ cValToChar(nQtdVen) )
										Conout(" - Valor Unitario: "  		+ cValToChar(nPrcVen) )
										Conout(" - Valor Total: " 			+ cValToChar(nTotal) )
										Conout(" - Data Abastecimento: " 	+ DtoC(dDataAbast) )
										Conout(" - Hora: " 			   		+ cHora )
										Conout(" - Minuto: " 				+ cMinuto )
										Conout(" - Numero abastecimento: " 	+ cNumIdent )
										Conout(" - Identfid: " 			+ cIdentifid )
										Conout(" - Encerrante: "   			+ cValToChar(nEncerra) )
										if MIC->MIC_XMILHA > 0
											Conout(" - Encerrante sem milhao: " + cValToChar( (nEncerra-(MIC->MIC_XMILHA * 1000000)) ) )
										endif
										Conout("")
									endif

									nPrcTab := U_URetPrec(cProduto,"",.F.)

									If !lPrcDifTab .and. nPrcTab <> nPrcVen
										cTexto := " " + CRLF ;
											+ ">> EXISTE DIFERENCA DE PRECO ENTRE: PRECO DE BICO x PRECO DE TABELA << " + CRLF ;
											+ " " + CRLF ;
											+ "DATA: "+DtoC(Date())+"" + CRLF ;
											+ "HORA: "+Time()+"" + CRLF ;
											+ " " + CRLF ;
											+ "CONCENTRADORA: "+cConcent+"" + CRLF ;
											+ "NUM. BICO: "+cNumBico+"" + CRLF ;
											+ "NUM. LOGICO: "+cNLogic+"" + CRLF ;
											+ "PRODUTO: "+AllTrim(cProduto)+" - "+MHZ->MHZ_DESPRO + CRLF ;
											+ " " + CRLF ;
											+ "PRECO BICO: "+cValToChar(nPrcVen)+"" + CRLF ;
											+ "PRECO TABELA: "+cValToChar(nPrcTab)+"" + CRLF ;
											+ " " + CRLF ;
											+ "STRING DE RETORNO: "+cRetorno+"" + CRLF ;
											+ " " + CRLF ;
											+ " " + CRLF

										if lLogAbAuto
											cNomeArq := "LOG_TRETE001_"+DtoS(dDataBase)+"_"+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)+".log"
											U_UCriaLog(cErroLOG+"\"/*cPasta*/,cNomeArq/*cNomeArq*/,cTexto/*cTexto*/)
										endif
									EndIf

									aCampos := {}
									aAdd( aCampos, { 'MID_FILIAL'	, xFilial("MID") 						} )
									aAdd( aCampos, { 'MID_CODBIC' 	, cNumBico  							} )
									aAdd( aCampos, { 'MID_DATACO' 	, Iif(cHoraRef>cHoraMin,DaySum(dDataAbast,1),dDataAbast) } )
									aAdd( aCampos, { 'MID_HORACO' 	, cHora + ":" + cMinuto					} )
									aAdd( aCampos, { 'MID_XPROD' 	, cProduto								} )
									aAdd( aCampos, { 'MID_CODBOM' 	, MIC->MIC_CODBOM  		   				} )
									aAdd( aCampos, { 'MID_XCONCE' 	, cConcent		  		   				} )
									aAdd( aCampos, { 'MID_CODTAN' 	, MIC->MIC_CODTAN						} )
									aAdd( aCampos, { 'MID_NLOGIC' 	, cNLogic  			   					} )
									aAdd( aCampos, { 'MID_LADBOM' 	, MIC->MIC_LADO  			   			} )
									aAdd( aCampos, { 'MID_LITABA' 	, nQtdVen  								} )
									aAdd( aCampos, { 'MID_PREPLI' 	, nPrcVen  								} )
									aAdd( aCampos, { 'MID_TOTAPA' 	, nTotal								} )
									aAdd( aCampos, { 'MID_ENCFIN' 	, nEncerra  		   					} )
									aAdd( aCampos, { 'MID_RFID' 	, cIdentifid		   					} )
									aAdd( aCampos, { 'MID_DTBASE' 	, dDataRef	 							} )
									aAdd( aCampos, { 'MID_LEITUR' 	, PadL(AllTrim(cNumIdent),TamSx3("MID_LEITUR")[1],"0") } )
									aAdd( aCampos, { 'MID_ENCINI'   , (nEncerra-nQtdVen)													   } ) //Encerrante inicial
									aAdd( aCampos, { 'MID_NUMORC'	, "P" } ) //Abastecimento Pendente
									aAdd( aCampos, { 'MID_CODANP'	, MHZ->MHZ_CODANP } ) 
									aAdd( aCampos, { 'MID_PBIO'		, MHZ->MHZ_PBIO } ) 
									aAdd( aCampos, { 'MID_UFORIG'	, MHZ->MHZ_UFORIG } ) 
									aAdd( aCampos, { 'MID_PORIG'	, MHZ->MHZ_PORIG } ) 
									aAdd( aCampos, { 'MID_INDIMP'	, MHZ->MHZ_INDIMP } ) 
									aAdd( aCampos, { 'MID_ENVSPE'	, "S" } ) //Envia SPED: S-Sim;N-Nao

									aAdd(aAbastecimento,aCampos)

								elseif lLogAbast
									Conout("")
									Conout(" >> ABASTECIMENTO ZERADO!")
									Conout(" >> DADOS DO ABASTECIMENTO: ")
									Conout("")
									Conout(" - Bico: " 		   	   		+ cNumBico )
									Conout(" - N. Logico: " 		   	+ cNLogic )
									Conout(" - Litros: " 		   		+ cValToChar(nQtdVen) )
									Conout(" - Valor Unitario: "  		+ cValToChar(nPrcVen) )
									Conout(" - Valor Total: " 			+ cValToChar(nTotal) )
									Conout(" - Dt Abastecimento: " 		+ DtoC(dDataAbast) )
									Conout(" - Hora: " 			   		+ cHora )
									Conout(" - Minuto: " 				+ cMinuto )
									Conout(" - Numero abastecimento: " 	+ cNumIdent )
									Conout(" - Identfid: " 			    + cIdentifid )
									Conout(" - Encerrante: "   			+ cValToChar(nEncerra) )
									Conout("")
								endif

							else
								if lLogAbast
									Conout("")
									Conout(" >> ID " + cNumIdent + " JA CADASTRADO" )
									Conout(" >> Exit - sai do While .T.")
									Conout("")
								endif
								Exit //sai do While .T.
							endif
						endif

					endif

					if !Empty(cNumIdent)
						// pego o número do abastecimento anterior
						cNumIdent := Tira1(cNumIdent)

						// monto a string para ler o último abastecimento da bomba posicionada
						cStrAbAnt := "2||POST|REQ_GET_SALE_DETAIL|||SID=" + cNumIdent + "|^"
						cStrAbAnt := PADL(cValToChar(Len(cStrAbAnt)),5,"0") + "|5|" + cStrAbAnt

						if lLogAbast
							Conout("")
							Conout(" >> COMANDO LEITURA DE **ULTIMO** ABASTECIMENTO (COMANDO) - cStrAbAnt: " + cStrAbAnt + "")
							Conout("")
						endif

						// envio comando para fusion
						U_XSocketP(cIP,nPorta,cStrAbAnt,@cRetorno)

						if lLogAbast
							Conout("")
							Conout(" >> COMANDO LEITURA DE **ULTIMO** ABASTECIMENTO (RETORNO) - cRetorno: " + cRetorno + "")
							Conout("")
						endif

						// transformo a string de retorno em array
						aAbast := StrToKarr(cRetorno,"|")
					else
						if lLogAbast
							Conout("")
							Conout(" >> ID DO ABASTECIMENTO VAZIO" )
							Conout(" >> Exit - sai do While .T.")
							Conout("")
						endif
						Exit //sai do While .T.
					endif

				endif

			EndDo

			if Len (aAbastecimento) > 0

				// identifico qual posição do array está o campo com o ID do abastecimento ateste
				nPosIdAbast := aScan(aAbastecimento[1],{|x| AllTrim(x[1]) == "MID_LEITUR" })

				// ordento o array na ordem crescente do ID do abastecimento
				aAbastecimento := aClone(aSort(aAbastecimento,,,{|x, y| x[nPosIdAbast,2] < y[nPosIdAbast,2] }))

				// percorro todos os abastecimentos da bomba posicionada
				For nY := 1 To Len(aAbastecimento)
					// faço a gravação do abastecimento
					If U_GrvAbMID(aAbastecimento[nY])
						if lLogAbast
							Conout("")
							Conout(" >> ABASTECIMENTO INCLUIDO COM SUCESSSO: " + MID->MID_CODABA + "!!!")
							Conout("")
						endif
					Endif
				Next nY

			endif

		Next nX

	endif

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return()

/*
Programa  AbFusionNew
Desc.     Função que faz a leitura do abastecimento da Fusion
Param.  1 - Código da Concentradora
		2 - IP
		3 - Porta
*/

Static Function AbFusionNew(cConcent,cIp,nPorta)

	Local aAbastecimento:= {}
	Local aAbast		:= {}
	Local cStrAbAnt		:= ""
	Local cLadoBomba	:= ""
	Local cIdentifid	:= ""
	Local nQtdVen		:= 0
	Local nPrcVen		:= 0
	Local nPrcTab		:= 0
	Local cNumBico 		:= ""
	Local cProduto 		:= ""
	Local nPosIdAbast	:= 0
	Local nPosError		:= 0
	Local nPosIdentif	:= 0 //TAG com a identificação do vendedor
	Local nX			:= 0
	Local nY			:= 0
	Local nTotal		:= 0
	Local cRetorno		:= ""
	Local nTamLado		:= TamSX3("MIC_LADO")[1]
	Local nTamNLogic	:= TamSX3("MIC_NLOGIC")[1]
	Local dDataRef		:= Date()
	Local cNLogic		:= ""
	Local lJaCadastrado := .F.
	Local cNumIdent		:= "" //id unico do abastecimento (codigo de leitura)

	Local cHoraRef		:= Time()
	Local cHoraMin		:= SuperGetMV("MV_XFCHHMI", .F./*lHelp*/, "24:00:00") //Horário mínimo para processar o Fechamento Diário do Posto.
	Local nMaxLeit      := SuperGetMV("MV_XMAXFUS",.F.,100) //número máximo de leitura da concentradora fusion por processamento
	Local nCountLe		:= 0
	Local cIdAbMID		:= ""

	Local cPasta   := "\AUTOCOM"
	Local cErroLOG := "\AUTOCOM\CONCENTRADORA"  //+"LOG" + cEmpAnt + StrTran(Alltrim(cFilAnt)," ","")
	Local cNomeArq := ""
	Local cTexto   := ""
	Local lPrcDifTab := SuperGetMV( "MV_XPDFTAB", , .F. ) // Permite baixa de abastecimento cujo o preço de bomba é diferente do preço de tabela

	Local cCondicao	 	:= ""
	Local bCondicao  	:= NIL

	Local nTentativas := 10 //numero de tentativa para correção
	Local nQtdBkp := 0
	Local lBicoAtivo := .F.

	if lLogAbast
		Conout("")
		Conout("")

		Conout("")
		Conout(" >> CONECTANDO NA CONCENTRADORA MODELO FUSION")
		Conout(" 	- DATA INI: " + DtoC(Date()))
		Conout(" 	- HORA INI: " + Time())
	endif

	If !ExistDir(cPasta)
		nRet := MakeDir( cPasta )
		If nRet != 0
			if lLogAbast
				Conout( "Não foi possível criar o diretório "+cPasta+". Erro: " + cValToChar( FError() ) )
			endif
		EndIf
	EndIf

	If !ExistDir(cErroLOG )
		nRet := MakeDir( cErroLOG  )
		If nRet != 0
			if lLogAbast
				Conout( "Não foi possível criar o diretório "+cErroLOG +". Erro: " + cValToChar( FError() ) )
			endif
		EndIf
	EndIf

	//recupera o contador 
	MHX->(DbSetOrder(1)) // MHX_FILIAL+MHX_CODCON
	If MHX->(DbSeek(xFilial("MHX") + cConcent))
		If MHX->( FieldPos("MHX_XLEITU") ) > 0
			cIdAbMID := MHX->MHX_XLEITU

		Else
			// posiciona no ultimo abastecimento lido da concentradora
			cCondicao := " MID->MID_FILIAL = '" + xFilial("MID") + "' "
			cCondicao += " .AND. MID->MID_XCONCE = '" + cConcent + "' "

			// utiliza o indice pelo código de leitura
			MID->(DbOrderNickName("MID_003")) //MID_FILIAL+MID_XCONCE+MID_LEITUR

			// limpo os filtros da MID
			MID->(DbClearFilter())

			// faço um filtro na MID
			bCondicao 	:= "{|| " + cCondicao + " }"
			MID->(DbSetFilter(&bCondicao,cCondicao))

			// posiciono no último abastecimento desta concentradora
			MID->(DbGoBottom())

			If MID->(!Eof())
				cIdAbMID := MID->MID_LEITUR
			Else
				cIdAbMID := PadR("0",TamSx3("MID_LEITUR")[01])
			EndIf

			// limpo os filtros da MID
			MID->(DbClearFilter())

		EndIf
	EndIf

	if lLogAbast
		Conout("")
		Conout(" >> CONTADOR DA FUSION ENCONTRADO (ID):")
		Conout(" 	- cIdAbMID: " + cIdAbMID)
	endif

	If !Empty(cIdAbMID)

		cNumIdent := cValToChar(Val(cIdAbMID)+1) //-- proximo ID da bomba

		While nCountLe < nMaxLeit

			nCountLe++
			Sleep(1000) //-- aguarda 1 segundo

			if lLogAbast
				Conout("")
				Conout(" 	- ID DO ULTIMO ABASTECIMENTO PROTHEUS: " + cIdAbMID)
				Conout(" 	- ID DO PROXIMO ABASTECIMENTO CONCENTRADORA A SER LIDO: " + cNumIdent)
			endif

			// monto a string para ler o abastecimento pelo ID informado
			cStrAbAnt := "2||POST|REQ_GET_SALE_DETAIL|||SID=" + cNumIdent + "|^"
			cStrAbAnt := PADL(cValToChar(Len(cStrAbAnt)),5,"0") + "|5|" + cStrAbAnt

			if lLogAbast
				Conout("")
				Conout(" >> (COMANDO) LEITURA DE ABASTECIMENTO PELO ID: "+cNumIdent)
				Conout(" 	- cStrAbAnt: " + cStrAbAnt + "")
			endif

			// envio comando para fusion
			U_XSocketP(cIP,nPorta,cStrAbAnt,@cRetorno) //-- ler o abastecimento pelo ID informado

			// transformo a string de retorno em array
			aAbast := StrToKarr(cRetorno,"|")

			// verifico se existe a TAG que informa se existe erro
			nPosError := aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "RC="})

			If Empty(cRetorno)
				if lLogAbast
					Conout("")
					Conout(" >> ERRO NO RETORNO **VAZIO**")
				endif
				Exit //sai do While

				//ElseIf nPosError > 0 .AND. AllTrim(StrTran(aAbast[nPosError],"RC=","")) <> "OK" .AND. "SSF_TRANS_ERR_SALE_DETAIL_NOT_FOUND" $ StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,4) == "MSG="})],"MSG=","")
				//	Conout("")
				//	Conout(" >> ABASTECIMENTO NAO ENCONTRADO: " + StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,4) == "MSG="})],"MSG=",""))
				//	// pego o número do proximo abastecimento a ser lido
				//	cNumIdent := cValToChar(Val(cNumIdent)+1)
				//	Loop //vai para o Proximo While

			ElseIf nPosError > 0 .AND. AllTrim(StrTran(aAbast[nPosError],"RC=","")) <> "OK" // se tiver retornado erro
				if lLogAbast
					Conout("")
					Conout(" >> ERRO NO RETORNO DA CONCENTRADORA: " + StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,4) == "MSG="})],"MSG=",""))
				endif
				Exit //sai do While

			Else

				// encontro as TAG's referentes aos dados do abastecimento
				cLadoBomba	:= PADL(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "PM="})],"PM=",""),nTamLado,"0")
				cNumLogic 	:= PADL(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "HO="})],"HO=",""),nTamNLogic,"0")
				dDataAbast	:= STOD(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "DA="})],"DA=",""))
				cHoraAbast	:= StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "TI="})],"TI=","")
				cHora		:= SubStr(cHoraAbast,1,2)
				cMinuto		:= SubStr(cHoraAbast,3,2)
				nQtdVen		:= Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "VO="})],"VO=",""))
				nPrcVen		:= Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "PU="})],"PU=",""))
				nTotal		:= Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "AM="})],"AM=",""))
				cNumIdent 	:= StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "SA="})],"SA=","") //id unico do abastecimento (codigo de leitura)
				nPosIdentif	:= aScan(aAbast,{|x| SubStr(AllTrim(x),1,7) == "PAY_IN="}) //TAG com a identificação do vendedor

				if lLogAbast
					Conout("")
					Conout(" 	- (LEITURA) NUMERO DE BOMBA: " + AllTrim(cLadoBomba) + "")
					Conout(" 	- (LEITURA) ID DO ABASTECIMENTO: " + cNumIdent)
					Conout(" 	- (LEITURA) DT ABASTECIMENTO: " + DtoC(dDataAbast))
					Conout(" 	- (LEITURA) HR ABASTECIMENTO: "+ cHora)
				endif

				// posiciono na tabela de bicos
				MIC->(DbOrderNickName("MIC_001")) //MIC_FILIAL+MIC_XCONCE+MIC_LADO+MIC_NLOGIC
				if MIC->(DbSeek(xFilial("MIC") + cConcent + cLadoBomba + cNumLogic))
						//.AND. MIC->MIC_STATUS <> "2" // se o bico estiver ativo

					lBicoAtivo := .F.
					While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_XCONCE+MIC->MIC_LADO+MIC->MIC_NLOGIC == xFilial("MIC") + cConcent + cLadoBomba + cNumLogic
						if  ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataAbast) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataAbast))
							lBicoAtivo := .T.
							EXIT
						endif
						MIC->(DBSkip())
					EndDO

					if lBicoAtivo
						// posiciono no grupo do tanque
						MHZ->(DbSetOrder(1)) //MHZ_FILIAL+MHZ_CODTAN
						If MHZ->(DbSeek( xFilial("MHZ") + MIC->MIC_CODTAN )) ;
							.AND. ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dDataAbast) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dDataAbast))

							//incluido por danilo 05/07/2019
							//Quando reinicia automação, o primeiro abastecimento pendente chega com valor unitario zerado (demais campos certo);
							If nPrcVen == 0 .AND. nQtdVen > 0
								nPrcVen := U_URetPrec(MHZ->MHZ_CODPRO,"",.F.)
								if lLogAbast
									Conout(" >> ABASTECIMENTO COM PRECO UNITARIO ZERADO. AJUSTADO PARA PRECO TABELA.")
								endif
							EndIf

							// ajusta o TOTAL para o numero de casas decimais que o sistema trabalha: L2_VLRITEM
							nTotal := A410Arred(nTotal,"L2_VLRITEM")

							// tratamento para não haver divergencia entre o total da bomba e o total do cupom

							If nPrcVen == 0
								if lLogAbast
									Conout(" - ESTE ABASTECIMENTO SERA DESCONSIDERADO POIS ESTA COM O PRECO UNITARIO ZERADO")
								endif
							ElseIf nQtdVen == 0
								if lLogAbast
									Conout(" - ESTE ABASTECIMENTO SERA DESCONSIDERADO POIS ESTA COM A QUANTIDADE ZERADA")
								endif
							Else

								// quando TOTAL é maior que QTD x PREÇO
								nTentativas := 10 //numero de tentativa para correção
								nQtdBkp := nQtdVen
								While nTentativas > 0 .and. nTotal > A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
									if lLogAbast
										conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO TOTAL ["+cValToChar(nTotal)+"], FOI ADICIONADO 0,001 NA QUANTIDADE")
										conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ANTES ["+cValToChar(nQtdVen)+"]")
									endif
									nQtdVen += 0.001
									if lLogAbast
										conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD DEPOIS ["+cValToChar(nQtdVen)+"]")
									endif
									nTentativas --
									If nTotal = A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
										Exit //sai do While
									ElseIf A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM") > nTotal //não funcionou, aborta o ajuste
										nQtdVen := nQtdBkp
										if lLogAbast
											conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ["+cValToChar(nQtdVen)+"] - ABORTA AJUSTE")
										endif
										Exit //sai do While
									EndIf
								EndDo

								// quando TOTAL é menor que QTD x PREÇO
								nTentativas := 10 //numero de tentativa para correção
								nQtdBkp := nQtdVen
								While nTentativas > 0 .and. nTotal < A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
									if lLogAbast
										conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO TOTAL ["+cValToChar(nTotal)+"], FOI SUBTRAIDO 0,001 NA QUANTIDADE")
										conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ANTES ["+cValToChar(nQtdVen)+"]")
									endif
									nQtdVen -= 0.001
									if lLogAbast
										conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD DEPOIS ["+cValToChar(nQtdVen)+"]")
									endif
									nTentativas --
									If nTotal = A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM")
										Exit //sai do While
									ElseIf A410Arred(nPrcVen * nQtdVen,"L2_VLRITEM") < nTotal //não funcionou, aborta o ajuste
										nQtdVen := nQtdBkp
										if lLogAbast
											conout(" - TRATAMENTO PARA ARREDONDAMENTO ABASTECIMENTO QTD ["+cValToChar(nQtdVen)+"] - ABORTA AJUSTE")
										endif
										Exit //sai do While
									EndIf
								EndDo

							EndIf

							// verifico se existe a TAG com a identificação do vendedor
							If nPosIdentif > 0

								cIdentifid	:= StrTran(aAbast[nPosIdentif],"PAY_IN=","")
								aIdentifid 	:= StrToKarr(cIdentifid,"$")

								// se as tags do identifid vierem preenchidas
								If Len(aIdentifid) > 0

									// verifico a posição da TAG 'TAG='
									nPosIdentif := aScan(aIdentifid,{|x| SubStr(AllTrim(x),1,4) == "TAG="})

									// se a TAG estiver preenchida
									If nPosIdentifid > 0
										cIdentifid := StrTran(aIdentifid[nPosIdentifid],"TAG=","")
										cIdentifid := StrTran(cIdentifid,"~","")
									Else
										cIdentifid := ""
									EndIf

								Else
									cIdentifid := ""
								EndIf

							Else
								cIdentifid := ""
							EndIf

							// verifico se a tag do encerrante está preenchida
							If aScan(aAbast,{|x| SubStr(AllTrim(x),1,4) == "FVO="}) > 0
								nEncerra := Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,4) == "FVO="})],"FVO=",""))
							ElseIf aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "FV="}) > 0
								nEncerra := Val(StrTran(aAbast[aScan(aAbast,{|x| SubStr(AllTrim(x),1,3) == "FV="})],"FV=",""))
							Else
								nEncerra := 0
							EndIf

							// valido se o abastecimento já está cadastrado
							MID->(DbOrderNickName("MID_003")) //MID_FILIAL+MID_XCONCE+MID_LEITUR
							lJaCadastrado := MID->(DbSeek(xFilial("MID") + cConcent + PadL(AllTrim(cNumIdent),TamSx3("MID_LEITUR")[1],"0")))

							If !lJaCadastrado .AND. !Empty(cNumIdent)

								cNumBico := MIC->MIC_CODBIC
								cProduto := MHZ->MHZ_CODPRO
								cNLogic	 := MIC->MIC_NLOGIC

								If nQtdVen > 0 //-- tratamento para não gravar abastecimento zerado

									// adiciono a casa do milhao
									nEncerra := nEncerra + (MIC->MIC_XMILHA * 1000000)
									if lLogAbast
										Conout("")
										Conout(" >> DADOS DO ABASTECIMENTO: ")
										Conout("")
										Conout(" - Bico: " 		   	   		+ MIC->MIC_CODBIC )
										Conout(" - Litros: " 		   		+ cValToChar(nQtdVen) )
										Conout(" - Valor Unitario: "  		+ cValToChar(nPrcVen) )
										Conout(" - Valor Total: " 			+ cValToChar(nTotal) )
										Conout(" - Data Abastecimento: " 	+ DtoC(dDataAbast) )
										Conout(" - Hora: " 			   		+ cHora )
										Conout(" - Minuto: " 				+ cMinuto )
										Conout(" - Numero abastecimento: " 	+ cNumIdent )
										Conout(" - Identfid: " 			    + cIdentifid )
										Conout(" - Encerrante: "   			+ cValToChar(nEncerra) )
										If MIC->MIC_XMILHA> 0
											Conout(" - Encerrante sem milhao: " + cValToChar( (nEncerra-(MIC->MIC_XMILHA * 1000000)) ) )
										EndIf
										Conout("")
									endif

									nPrcTab := U_URetPrec(cProduto,"",.F.)

									If !lPrcDifTab .and. nPrcTab <> nPrcVen
										cTexto := " " + CRLF ;
											+ ">> EXISTE DIFERENCA DE PRECO ENTRE: PRECO DE BICO x PRECO DE TABELA << " + CRLF ;
											+ " " + CRLF ;
											+ "DATA: "+DtoC(Date())+"" + CRLF ;
											+ "HORA: "+Time()+"" + CRLF ;
											+ " " + CRLF ;
											+ "CONCENTRADORA: "+cConcent+"" + CRLF ;
											+ "NUM. BICO: "+cNumBico+"" + CRLF ;
											+ "NUM. LOGICO: "+cNLogic+"" + CRLF ;
											+ "PRODUTO: "+AllTrim(cProduto)+" - "+MHZ->MHZ_DESPRO + CRLF ;
											+ " " + CRLF ;
											+ "PRECO BICO: "+cValToChar(nPrcVen)+"" + CRLF ;
											+ "PRECO TABELA: "+cValToChar(nPrcTab)+"" + CRLF ;
											+ " " + CRLF ;
											+ "STRING DE RETORNO: "+cRetorno+"" + CRLF ;
											+ " " + CRLF ;
											+ " " + CRLF

										if lLogAbAuto
											cNomeArq := "LOG_TRETE001_"+DtoS(dDataBase)+"_"+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)+".log"
											U_UCriaLog(cErroLOG+"\"/*cPasta*/,cNomeArq/*cNomeArq*/,cTexto/*cTexto*/)
										endif
									EndIf

									aCampos := {}
									aAdd( aCampos, { 'MID_FILIAL'	, xFilial("MID") 						} )
									aAdd( aCampos, { 'MID_CODBIC' 	, cNumBico  							} )
									aAdd( aCampos, { 'MID_DATACO' 	, Iif(cHoraRef>cHoraMin,DaySum(dDataAbast,1),dDataAbast) } )
									aAdd( aCampos, { 'MID_HORACO' 	, cHora + ":" + cMinuto					} )
									aAdd( aCampos, { 'MID_XPROD' 	, cProduto								} )
									aAdd( aCampos, { 'MID_CODBOM' 	, MIC->MIC_CODBOM  		   				} )
									aAdd( aCampos, { 'MID_XCONCE' 	, cConcent		  		   				} )
									aAdd( aCampos, { 'MID_CODTAN' 	, MIC->MIC_CODTAN						} )
									aAdd( aCampos, { 'MID_NLOGIC' 	, cNLogic  			   					} )
									aAdd( aCampos, { 'MID_LADBOM' 	, MIC->MIC_LADO  			   			} )
									aAdd( aCampos, { 'MID_LITABA' 	, nQtdVen  								} )
									aAdd( aCampos, { 'MID_PREPLI' 	, nPrcVen  								} )
									aAdd( aCampos, { 'MID_TOTAPA' 	, nTotal								} )
									aAdd( aCampos, { 'MID_ENCFIN' 	, nEncerra  		   					} )
									aAdd( aCampos, { 'MID_RFID' 	, cIdentifid		   					} )
									aAdd( aCampos, { 'MID_DTBASE' 	, dDataRef	 							} )
									aAdd( aCampos, { 'MID_LEITUR' 	, PadL(AllTrim(cNumIdent),TamSx3("MID_LEITUR")[1],"0") } )
									aAdd( aCampos, { 'MID_ENCINI'   , (nEncerra-nQtdVen)													   } ) //Encerrante inicial
									aAdd( aCampos, { 'MID_NUMORC'	, "P" } ) //Abastecimento Pendente
									aAdd( aCampos, { 'MID_CODANP'	, MHZ->MHZ_CODANP } ) 
									aAdd( aCampos, { 'MID_PBIO'		, MHZ->MHZ_PBIO } ) 
									aAdd( aCampos, { 'MID_UFORIG'	, MHZ->MHZ_UFORIG } ) 
									aAdd( aCampos, { 'MID_PORIG'	, MHZ->MHZ_PORIG } ) 
									aAdd( aCampos, { 'MID_INDIMP'	, MHZ->MHZ_INDIMP } ) 
									aAdd( aCampos, { 'MID_ENVSPE'	, "S" } ) //Envia SPED: S-Sim;N-Nao

									aAdd(aAbastecimento,aCampos)

									// grava os abastecimentos
									If Len (aAbastecimento) > 0

										// identifico qual posição do array está o campo com o ID do abastecimento ateste
										nPosIdAbast := aScan(aAbastecimento[1],{|x| AllTrim(x[1]) == "MID_LEITUR"})

										// ordento o array na ordem crescente do ID do abastecimento
										aAbastecimento := aClone(aSort(aAbastecimento,,,{|x, y| x[nPosIdAbast,2] < y[nPosIdAbast,2] }))

										// percorro todos os abastecimentos da bomba posicionada
										For nY := 1 To Len(aAbastecimento)
											// faço a gravação do abastecimento
											If U_GrvAbMID(aAbastecimento[nY])
												if lLogAbast
													Conout("")
													Conout(" >> ABASTECIMENTO INCLUIDO COM SUCESSSO: "+MID->MID_CODABA+"!!!")
												endif
											EndIf
										Next nY

										aAbastecimento := {}

									EndIf

								Elseif lLogAbast
									Conout("")
									Conout(" >> ABASTECIMENTO ZERADO!")
									Conout(" >> DADOS DO ABASTECIMENTO: ")
									Conout("")
									Conout(" - Bico: " 		   	   		+ cNumBico )
									Conout(" - N. Logico: " 		   	+ cNLogic )
									Conout(" - Litros: " 		   		+ cValToChar(nQtdVen) )
									Conout(" - Valor Unitario: "  		+ cValToChar(nPrcVen) )
									Conout(" - Valor Total: " 			+ cValToChar(nTotal) )
									Conout(" - Dt Abastecimento: " 		+ DtoC(dDataAbast) )
									Conout(" - Hora: " 			   		+ cHora )
									Conout(" - Minuto: " 				+ cMinuto )
									Conout(" - Numero abastecimento: " 	+ cNumIdent )
									Conout(" - Identfid: " 			    + cIdentifid )
									Conout(" - Encerrante: "   			+ cValToChar(nEncerra) )
									Conout("")
								EndIf

							Elseif lLogAbast
								Conout("")
								Conout(" >> ID " + cNumIdent + " JA CADASTRADO" )

							EndIf

						Elseif lLogAbast
							Conout("")
							Conout(" >> GRUPO DE TANQUE " + AllTrim(MIC->MIC_CODTAN) + " INVALIDO OU DESATIVADO")
						EndIf
						
					Elseif lLogAbast
						Conout("")
						Conout(" >> NUMERO DE BICO NAO ATIVO")
						Conout("  	- CONCENTRADORA: " + cConcent)
						Conout("  	- LADO: " + cLadoBomba)
						Conout("	- N.LOGICO: " + cNumLogic)
					EndIf

				Elseif lLogAbast
					Conout("")
					Conout(" >> NUMERO DE BICO NAO CADASTRADO")
					Conout("  	- CONCENTRADORA: " + cConcent)
					Conout("  	- LADO: " + cLadoBomba)
					Conout("	- N.LOGICO: " + cNumLogic)

				EndIf

			EndIf

			// pego o número do proximo abastecimento a ser lido
			cNumIdent := cValToChar(Val(cNumIdent)+1)

		EndDo

		// -- ajusta contador da concentradora
		MHX->(DbSetOrder(1)) // MHX_FILIAL+MHX_CODCON
		If MHX->(DbSeek(xFilial("MHX") + cConcent))
			If MHX->( FieldPos("MHX_XLEITU") ) > 0 .and. MHX->MHX_XLEITU = cIdAbMID
				RecLock("MHX",.F.)
				MHX->MHX_XLEITU := cValToChar(Val(cNumIdent)-1)
				MHX->(msUnlock())
				if lLogAbast
					Conout("")
					Conout(" >> NOVO PONTEIRO DE LEITURA GRAVADO!!!")
					Conout("  	- ID DO ULTIMO ABASTECIMENTO PROTHEUS: " + MHX->MHX_XLEITU )
				endif
			EndIf
		EndIf

	Elseif lLogAbast
		Conout("")
		Conout(" >> ERRO NO PONTEIRO: **VAZIO**. FAVOR PREENCHER O CAMPO N.LEITURA (MHX_XLEITU)")

	EndIf

	if lLogAbast
		Conout("")
		Conout(" >> CONECTANDO NA CONCENTRADORA MODELO FUSION")
		Conout(" 	- DATA FIM: " + DtoC(Date()))
		Conout(" 	- HORA FIM: " + Time())

		Conout("")
		Conout("")
	endif

Return()

/*/{Protheus.doc} StatusCBC
Função que faz a interpretação do status dos bicos da CBC.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cConcent, characters, Código da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@type function
/*/
Static Function StatusCBC(cConcent,cIP,nPorta)

	Local aArea		:= GetArea()
	Local aAreaMIC	:= MIC->(GetArea())
	Local aRet 		:= {}
	Local aCanais	:= {}
	Local cRet		:= ""
	Local cStatus	:= ""
	Local cStrEnvio	:= ""
	Local lConect	:= .F.

/*
Tabela de códigos de bico CBC-04
(SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) 51 CARACTERES
Onde X representa os caracteres ASCII: ( A , B , L , C , F , E , P )
As posições representativas dos códigos de bico são:
(S <04> <05> <06> <07> <08> <09> <0A> <0B> <0C> <0D> <0E> <0F> <10> <11> <12> <13>
<14> <15> <16> <17> <18> <19> <1 A> <1B> <1C> <1D> <1E> <1F> <20> <21> <22> <23>)

Tabela de códigos de Status
L - Bomba encontra-se livre para abastecer.
B - Bomba bloqueada para realizar abastecimentos.
C - Bomba concluiu abastecimento.
A - Bomba está em processo de abastecimento.
E - Bomba está aguardando liberação da automação para iniciar o processo de abastecimento.
F - Bomba não presente ou em falha
P - Bomba está pronta para abastecer.
*/

	aadd(aCanais,{"04","44","84","C4"}) // Canal 1, Bomba 1, Lado A
	aadd(aCanais,{"05","45","85","C5"}) // Canal 1, Bomba 1, Lado B
	aadd(aCanais,{"06","46","86","C6"}) // Canal 1, Bomba 2, Lado A
	aadd(aCanais,{"07","47","87","C7"}) // Canal 1, Bomba 2, Lado B

	aadd(aCanais,{"08","48","88","C8"}) // Canal 2, Bomba 1, Lado A
	aadd(aCanais,{"09","49","89","C9"}) // Canal 2, Bomba 1, Lado B
	aadd(aCanais,{"0A","4A","8A","CA"}) // Canal 2, Bomba 2, Lado A
	aadd(aCanais,{"0B","4B","8B","CB"}) // Canal 2, Bomba 2, Lado B

	aadd(aCanais,{"0C","4C","8C","CC"}) // Canal 3, Bomba 1, Lado A
	aadd(aCanais,{"0D","4D","8D","CD"}) // Canal 3, Bomba 1, Lado B
	aadd(aCanais,{"0E","4E","8E","CE"}) // Canal 3, Bomba 2, Lado A
	aadd(aCanais,{"0F","4F","8F","CF"}) // Canal 3, Bomba 2, Lado B

	aadd(aCanais,{"10","50","90","D0"}) // Canal 4, Bomba 1, Lado A
	aadd(aCanais,{"11","51","91","D1"}) // Canal 4, Bomba 1, Lado B
	aadd(aCanais,{"12","52","92","D2"}) // Canal 4, Bomba 2, Lado A
	aadd(aCanais,{"13","53","93","D3"}) // Canal 4, Bomba 2, Lado B

	aadd(aCanais,{"14","54","94","D4"}) // Canal 5, Bomba 1, Lado A
	aadd(aCanais,{"15","55","95","D5"}) // Canal 5, Bomba 1, Lado B
	aadd(aCanais,{"16","56","96","D6"}) // Canal 5, Bomba 2, Lado A
	aadd(aCanais,{"17","57","97","D7"}) // Canal 5, Bomba 2, Lado B

	aadd(aCanais,{"18","58","98","D8"}) // Canal 6, Bomba 1, Lado A
	aadd(aCanais,{"19","59","99","D9"}) // Canal 6, Bomba 1, Lado B
	aadd(aCanais,{"1A","5A","9A","DA"}) // Canal 6, Bomba 2, Lado A
	aadd(aCanais,{"1B","5B","9B","DB"}) // Canal 6, Bomba 2, Lado B

	aadd(aCanais,{"1C","5C","9C","DC"}) // Canal 7, Bomba 1, Lado A
	aadd(aCanais,{"1D","5D","9D","DD"}) // Canal 7, Bomba 1, Lado B
	aadd(aCanais,{"1E","5E","9E","DE"}) // Canal 7, Bomba 2, Lado A
	aadd(aCanais,{"1F","5F","9F","DF"}) // Canal 7, Bomba 2, Lado B

	aadd(aCanais,{"20","60","A0","E0"}) // Canal 8, Bomba 1, Lado A
	aadd(aCanais,{"21","61","A1","E1"}) // Canal 8, Bomba 1, Lado B
	aadd(aCanais,{"22","62","A2","E2"}) // Canal 8, Bomba 2, Lado A
	aadd(aCanais,{"23","63","A3","E3"}) // Canal 8, Bomba 2, Lado B

// string de envio para ler o status do bico
	cStrEnvio := "(&S)"

	if lLogAbast
		Conout(" >> COMANDO " + cStrEnvio + " - LEITURA DE STATUS DOS BICOS")
	endif

// chamo a função que faz conexão via socket
	lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

	If !lConect .OR. ValType(cRet) <> "C"
		if lLogAbast
			Conout(" >> CONEXAO NAO REALIZADA")
		endif
	else

		// elimino os caracteres reservados, deixando apenas o status dos bicos
		cRet := SubStr(cRet,3,32)

		MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
		MIC->(DbGoTop()) // posiciono no primeiro registro

		// percorro todos os bicos para identificar o status
		While MIC->(!Eof()) .AND. MIC->MIC_FILIAL == xFilial("MIC")

			if MIC->MIC_XCONCE == cConcent ;//.AND. MIC->MIC_STATUS == "1" // se o bico estiver ativo e a concentradora for CBC
				((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataBase) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataBase))

				cNumLogic := AllTrim(MIC->MIC_NLOGIC)

				nPos := aScan(aCanais,{|x| AllTrim(x[1]) == cNumLogic .OR. AllTrim(x[2]) == cNumLogic .OR. AllTrim(x[3]) == cNumLogic .OR. AllTrim(x[4]) == cNumLogic})

				if nPos > 0

					cStatus := SubStr(cRet,nPos,1)

					if cStatus == "A" // BICO ABASTECENDO
						cStatus := "A"
					elseif Empty(cStatus) .OR. cStatus $ "B/C/E/F" // BICO BLOQUEADO PARA USO
						cStatus := "B"
					else // DEMAIS STATUS
						cStatus := "L"
					endif

					aadd(aRet,{MIC->MIC_FILIAL+MIC->MIC_CODBIC+MIC->MIC_CODTAN,cStatus})

				endif

			endif

			MIC->(DbSkip())

		EndDo

	EndIf

	RestArea(aArea)
	RestArea(aAreaMIC)

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(aRet)


/*/{Protheus.doc} StatusFusion
Função que faz a interpretação do status dos bicos Fusion.

@author pablo
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cConcent, characters, Código da concentradora
@param cIP, characters, IP
@param nPorta, numeric, Porta
@type function
/*/
Static Function StatusFusion(cConcent,cIP,nPorta)

	Local aArea		:= GetArea()
	Local aAreaMIC	:= MIC->(GetArea())
	Local cRet		:= ""
	Local cStatus	:= ""
	Local aRet 		:= {}
	Local aStatus	:= {}
	Local cLado		:= ""
	Local cStrEnvio	:= ""
	Local lConect	:= .F.

	MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN
	MIC->(DbGoTop()) // posiciono no primeiro registro

	// percorro todos os bicos para localizar o status
	While MIC->(!Eof()) .AND. MIC->MIC_FILIAL == xFilial("MIC")

		if MIC->MIC_XCONCE == cConcent ; //.AND. MIC->MIC_STATUS == "1" // se o bico estiver ativo e for da concentradora posicionada
			.AND. ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataBase) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataBase))

			cLado 		:= AllTrim(MIC->MIC_LADO)
			cStrEnvio	:= ""
			lConect		:= .F.
			cRet		:= ""
			cStatus		:= ""
			aStatus		:= {}

			if !Empty(cLado) // se o lado do bico estiver preenchido

				cStrEnvio := "2||POST|REQ_PUMP_STATUS_ID_" + PADL(cLado,3,"0") + "||||^"
				cStrEnvio := PADL(cValToChar(Len(cStrEnvio)),5,"0") + "|5|" + cStrEnvio

				if lLogAbast
					Conout(" >> COMANDO " + cStrEnvio + " - MODO DO BICO")
				endif

				// envio comando para fusion
				lConect := U_XSocketP(cIP,nPorta,cStrEnvio,@cRet)

				if lConect

					// transformo a string de retorno em array
					aStatus := StrToKarr(cRet,"|")

					if Len(aStatus) > 0

						// verifico se o retorno tem a TAG com o status da bomba
						nPosStat := aScan(aStatus,{|x| SubStr(AllTrim(x),1,3) == "ST="})

						if nPosStat > 0

							cRet := AllTrim(StrTran(aStatus[nPosStat],"ST=",""))

							if cRet == "IDLE"
								cStatus := "B"
							elseif cRet == "AUTHORIZED"
								cStatus := "L"
							elseif cRet == "FUELLING" .OR. cRet == "STARTING" .OR. cRet == "PAUSED"
								cStatus := "A"
							elseif cRet == "ERROR"
								cStatus := "E"
							else
								cStatus := "B"
							endif

							aadd(aRet,{MIC->MIC_FILIAL+MIC->MIC_CODBIC+MIC->MIC_CODTAN,cStatus})

						endif

					endif

				endif

			endif

		endif

		MIC->(DbSkip())

	EndDo

	RestArea(aArea)
	RestArea(aAreaMIC)

	if lLogAbast
		Conout("")
		Conout("")
	endif
Return(aRet)


/*/{Protheus.doc} U_GrvAbMID
Funcao que faz a gravacao dos abastecimentos.

@author pablo
@since 16/10/2018
@version 1.0
@return ${return}, ${return_description}
@param aCampos, array, {NOME DO CAMPO, CONTEUDO}
@type function
/*/
Static Function U_GrvAbMID(aCampos)

	Local lRet 		:= .T.
	Local nI		:= 1
	Local lAux		:= .F.
	Local aErro		:= {}
	Local oAux
	Local oModel
	Local oStruct

	DbSelectArea("MID")

	if lLogAbast
		Conout(" >> INCLUSAO DO ABASTECIMENTO")
	endif

// Aqui ocorre o inst?ciamento do modelo de dados (Model)
	oModel := FWLoadModel( 'TRETA008' ) //Mvc dos abastecimentos

// Temos que definir qual a operação deseja: 3 - Inclusão / 4 - Alteraão / 5 - Exclusão
	oModel:SetOperation(3)

// Antes de atribuirmos os valores dos campos temos que ativar o modelo
	oModel:Activate()

// Instanciamos apenas referentes aos dados
	oAux := oModel:GetModel('MIDMASTER')

// Obtemos a estrutura de dados
	oStruct := oAux:GetStruct()
	aAux 	:= oStruct:GetFields()

	For nI := 1 To Len(aCampos)

		// Verifica se os campos passados existem na estrutura do modelo
		If ( nPos := aScan(aAux,{|x| AllTrim( x[3] )== AllTrim(aCampos[nI][1]) } ) ) > 0

			// ?feita a atribui?o do dado ao campo do Model
			If !( lAux := oModel:SetValue( 'MIDMASTER', aCampos[nI][1], (aCampos[nI][2] )) )

				// Caso a atribui?o n? possa ser feita, por algum motivo (valida?o, por
				// o m?odo SetValue retorna .F.
				lRet := .F.
				Exit

			EndIf

		EndIf

	Next nI

	If lRet

		// Faz-se a valida?o dos dados
		If ( lRet := oModel:VldData() )

			// Se o dados foram validados faz-se a grava?o efetiva dos dados (commit)
			oModel:CommitData()

		EndIf

	EndIf

	If !lRet

		// Se os dados n? foram validados obtemos a descri?o do erro para gerar LOG ou mensagem de aviso
		aErro := oModel:GetErrorMessage()

		AutoGrLog( "Id do formulario de origem: " 	+ ' [' + AllToChar( aErro[1] ) + ']' )
		AutoGrLog( "Id do campo de origem:      " 	+ ' [' + AllToChar( aErro[2] ) + ']' )
		AutoGrLog( "Id do formulario de erro:   " 	+ ' [' + AllToChar( aErro[3] ) + ']' )
		AutoGrLog( "Id do campo de erro:        " 	+ ' [' + AllToChar( aErro[4] ) + ']' )
		AutoGrLog( "Id do erro:                 " 	+ ' [' + AllToChar( aErro[5] ) + ']' )
		AutoGrLog( "Mensagem do erro:           " 	+ ' [' + AllToChar( aErro[6] ) + ']' )
		AutoGrLog( "Mensagem da solucao:        " 	+ ' [' + AllToChar( aErro[7] ) + ']' )
		AutoGrLog( "Valor atribuido:            " 	+ ' [' + AllToChar( aErro[8] ) + ']' )
		AutoGrLog( "Valor anterior:             " 	+ ' [' + AllToChar( aErro[9] ) + ']' )

		if lLogAbast
			Conout(" >> ABASTECIMENTO NAO CADASTRADO")
			Conout(MostraErro("\"))
		endif

	Else

		if lLogAbast
			Conout(" >> ABASTECIMENTO CADASTRADO COM SUCESSO")
		endif

	EndIf

// Desativamos o Model
	oModel:DeActivate()

Return(lRet)


/*/{Protheus.doc} TransSTR
Transforma em STRING de um determinado valor.

@author pablo
@since 18/10/2018
@version 1.0
@return ${return}, ${return_description}
@param nNum, numeric, descricao
@param nTam, numeric, descricao
@param nDec, numeric, descricao
@type function
/*/
Static Function TransSTR(nNum, nTam, nDec)
	Local cRet := ""

	cRet := TRANSFORM( nNum, "@E " + Replicate( "9", nTam ) + "." + Replicate( "9", nDec ) )
	cRet := StrTran( cRet, ".", "" )
	cRet := StrTran( cRet, ",", "" )
	cRet := PadL( AllTrim(cRet), nTam, "0")

Return cRet
