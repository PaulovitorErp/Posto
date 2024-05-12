#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'

/*/{Protheus.doc} TRETE022
Processa os JOBs do posto inteligente...


[REQUISICOES]
TRETE023 - Job para geração/estorno de financeiro das requisições incluidas no PDV - OFF-LINE

[COMPENSACAO]
TRETE024 - Job para geração/estorno de financeiro das compensações incluidas pelo PDV - OFF-LINE

[NCC_COMPENSACAO]
TRETE025 - Job para reprocessar NCC de Compensação - OFF-LINE

[CHQ_TROCO]
TRETE026 - Job faz a geração dos títulos de cheque troco, quando o modo OFF-LINE estiver ativo

[VALE_SERVICO]
TRETE034 - Job gera financeiro dos vales serviços - OFF-LINE

[LIMITE_OFFLINE]
TRETE050 - JOB responsável por atualizar valores de limites de credito de clientes e grupos de clientes

@author Pablo Cavalcante

@since 02/05/2019
@version 1.0
@return ${return}, ${return_description}

@param cFunc, characters, job a ser executado
@param cEmp, characters, grupo de empresa
@param cFilTrab, characters, filiais (separado por ,)
@param cIntervalo, characters, intervalo e milisegundos

@type function
/*/
User Function TRETE022(cFunc, cEmp, cFilTrab, cIntervalo, cXParam)
Local nHandle			   // Indica se o arquivo foi criado
Local nIntervalo 	:= 0   // Intervalo para o Loop
Local cFileName		:= ""  // Nome do arquivo
Local nCount 		:= 1   // Contador
Local cTemp			:= ""  // Temporario
Local aFiliais   	:= {}  // Filiais
Local lExProc 		:= .T. // Controla o while do Killapp
Local lMultFil 		:= .F. // Verifica se eh passado mais de uma filial no parametro
Local lCriouAmb		:= .F. // Verifica se o PREPARE ENVIRONMENT foi executado
Local nSleep := 0 // Utilizado para atribuicao na variavel nIntervalo
Local nTimes := 0 // Numero de loop antes de entrar no while
Local nX
Local cUser := '000000'
Local cISCPDV       := GetPvProfString("CPDV", "ISCPDV", "", GetAdv97()) // Felipe Sousa - 25/01/2024 - Verifico se é central PDV
Local cCOMCPDV      := GetPvProfString("CPDV", "COMCPDV", "", GetAdv97()) // Felipe Sousa - 25/01/2024 - Verifico se é PDV
//Local cIsCPDV := GetPvProfString("CONEXAOPDV", "CONECTADO", "", GetAdv97())


Default cIntervalo := 15000 //Conteudo do terceiro parametro (Parm4 do mp8srv.ini) -> é definido em milissegundos.
Default cXParam := ""

SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

If !FindFunction("U_"+cFunc)
	//Conout("TRETE022: Função "+cFunc+" nao encontrada/compilada no ambiente...")
	Return
EndIf

//Tratamento caso o quarto parametro seja passado ou nao.
If ValType(cIntervalo) <> "N"
	nSleep := Val(cIntervalo)
Else
	nSleep := cIntervalo
Endif

While nCount <= Len( cFilTrab )

	cTemp := ""
	While SubStr( cFilTrab, nCount, 1 ) <> "," .AND. nCount <= Len( cFilTrab )
		cTemp += SubStr( cFilTrab, nCount, 1 )
		nCount++
	End

	AADD( aFiliais, { cTemp } )
	nCount++

EndDo

nCount := 1

//Verifica o numero de filiais que esta sendo passado.
If Len(aFiliais) > 1
	lMultFil := .T.
Endif

For nX:=1 to Len(aFiliais)
	cFileName := cFunc + cEmp + aFiliais[ nX ][1] + "DBUG"
	FErase("TRETE022"+cFileName+".WRK")
Next nX

//Variavel lExProc inicializada como True
While !KillApp() .AND. lExProc

	cFileName := cFunc + cEmp + aFiliais[ nCount ][1] + "DBUG"
	If (!lMultFil .AND. lCriouAmb) .OR. ( nHandle := MSFCreate("TRETE022"+cFileName+".WRK") ) >= 0
		If lMultFil .OR. !lCriouAmb
			//Conout("TRETE022: "+"Empresa:" + cEmp + " Filial:" + aFiliais[ nCount ][1])  // "Empresa:" ### " Filial:"
			//Conout("            "+"Iniciando processo de "+cFunc+"...")  //"Iniciando processo de gravacao batch..."

			//RPCSetType(3)  // Nao comer licensa //TODO: ao debugar deve-se comentar essa linha...
			////Retirado PREPARE ENVARIMEND porque em alguns casos trava o JOB
			//RPCSetEnv(cEmp, aFiliais[ nCount ][1])

			//-- Preparar ambiente local na retagauarda //TODO: debug
			//RpcSetType(3) // Para nao consumir licenças na Threads
			//cEmpAnt := AllTrim(cEmp)
			//cFilAnt := AllTrim(aFiliais[ nCount ][1])
			//PREPARE ENVIRONMENT EMPRESA cEmpAnt FILIAL cFilAnt MODULO "FRT"

			//Para informar ao Server que consumirá licenças
			cEmpAnt := AllTrim(cEmp)
			cFilAnt := AllTrim(aFiliais[ nCount ][1])
			if cISCPDV == "1" .OR. cCOMCPDV == "1" //se é PDV
				RpcSetType(3) // Para nao consumir licenças na Threads
				RpcSetEnv(cEmpAnt, cFilAnt, , ,'FRT',)
			else
				RpcSetEnv(cEmpAnt, cFilAnt, , ,'FIN',)
			endif
			__CUSERID := cUser
			//nModulo := 12 //RpcSetEnv incia o modulo 5 por padrão, para validar AmIIn(12) foi preciso mudar nModulo
			LjGrvLog("TRETE022", "Processa os JOBs do posto inteligente...: ", {cEmpAnt,cFilAnt,nModulo}) 

			lCriouAmb := .T.

		Endif

		//
		// Executa o JOB
		//
		cFilAnt := aFiliais[ nCount ][1]
		dDataBase := Date()
		//&("U_"+cFunc+"('"+cEmp+"','"+aFiliais[ nCount ][1]+"')")
		&("U_"+cFunc+"("+iif(empty(cXParam),"","'"+cXParam+"'")+")") //não mais passa os parametros

		//Checa se o arquivo existe fora so while do SL1 para apagar quando n existir RX no SL1
		If ( nTimes > 30 ) .OR. ( nIntervalo == nSleep )
			If File("TRETE022"+cFileName+".FIM")
				//Conout("            "+"Solicitacao para finalizar "+cFunc+" atendida...")
				FErase("TRETE022"+cFileName+".FIM")
				Exit
			EndIf
			nTimes := 0
		EndIf

		nIntervalo := 0
		nTimes++

		nIntervalo := nSleep

		If ( nIntervalo > 0 )
			Sleep(nIntervalo)
		EndIf

		If lMultFil
			FClose(nHandle)
			FErase("TRETE022"+cFileName+".WRK")

			//Conout("            "+"Empresa:" + cEmp + " Filial:" + aFiliais[ nCount ][1]+" - "+"Processo de gravacao "+cFunc+" finalizado...")
		Endif

	Else
		//Conout(Repl("*",40)+Chr(10)+Chr(10))
		//Conout("TRETE022: "+"Empresa:" + cEmp + " Filial:" + aFiliais[ nCount ][1])
		//Conout("            "+"Processo de "+cFunc+" ja estava rodando...")

		lRetValue := .F.
		Exit
	EndIf

	If nCount < LEN( aFiliais )
		nCount := nCount + 1
	Else
		nCount := 1
	EndIf

EndDo

If (!lMultFil .OR. !lExProc)
	RESET ENVIRONMENT
EndIf

FClose(nHandle)
FErase("TRETE022"+cFileName+".WRK")

Return
